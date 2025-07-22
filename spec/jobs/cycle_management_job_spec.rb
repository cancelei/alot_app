require 'rails_helper'

RSpec.describe CycleManagementJob, type: :job do
  describe '#perform' do
    let!(:active_lottery_game) { create(:lottery_game, :with_active_cycles) }
    let!(:completed_lottery_game) { create(:lottery_game, :with_completed_cycles) }
    let!(:inactive_lottery_game) { create(:lottery_game, cycle_status: nil) }

    it 'processes only active lottery games' do
      expect_any_instance_of(CycleManagementJob).to receive(:process_lottery_game_cycles).with(active_lottery_game)
      expect_any_instance_of(CycleManagementJob).not_to receive(:process_lottery_game_cycles).with(completed_lottery_game)
      expect_any_instance_of(CycleManagementJob).not_to receive(:process_lottery_game_cycles).with(inactive_lottery_game)

      CycleManagementJob.perform_now
    end

    context 'when cycles are completed' do
      let!(:lottery_game) { create(:lottery_game, :with_active_cycles, payout_strategy: 'winner_takes_all') }
      let!(:winning_ticket) { create(:ticket, :winning, lottery_game: lottery_game, prize_amount: 50.0) }

      before do
        # Make cycles completed by setting start time far in the past
        lottery_game.update!(cycle_start_time: 12.hours.ago)
      end

      it 'completes cycles automatically' do
        expect(lottery_game.cycles_completed?).to be_truthy

        CycleManagementJob.perform_now

        lottery_game.reload
        expect(lottery_game.cycle_status).to eq('completed')
      end

      it 'processes payouts based on strategy' do
        expect {
          CycleManagementJob.perform_now
        }.to change { PayoutLog.count }.by_at_least(1)

        payout_log = PayoutLog.last
        expect(payout_log.payout_type).to eq('cycle_completion_winner_takes_all')
      end

      it 'logs successful completion' do
        expect(Rails.logger).to receive(:info).with("Processing completed cycles for lottery game: #{lottery_game.name}")
        expect(Rails.logger).to receive(:info).with("Successfully completed cycles for lottery game: #{lottery_game.name}")

        CycleManagementJob.perform_now
      end
    end

    context 'when cycles require admin review' do
      let!(:lottery_game) { create(:lottery_game, :with_active_cycles, payout_strategy: 'admin_discretion') }

      before do
        lottery_game.update!(cycle_start_time: 12.hours.ago)
      end

      it 'sets status to pending admin review' do
        CycleManagementJob.perform_now

        lottery_game.reload
        expect(lottery_game.cycle_status).to eq('pending_admin_review')
      end

      it 'sends admin notification email' do
        expect(AdminNotificationMailer).to receive(:cycle_requires_review).with(lottery_game).and_return(double(deliver_now: true))

        CycleManagementJob.perform_now
      end
    end

    context 'when error occurs during cycle completion' do
      let!(:lottery_game) { create(:lottery_game, :with_active_cycles) }

      before do
        lottery_game.update!(cycle_start_time: 12.hours.ago)
        allow(lottery_game).to receive(:complete_cycles!).and_raise(StandardError.new("Database error"))
      end

      it 'logs error and sends notification' do
        expect(Rails.logger).to receive(:error).with("Failed to complete cycles for lottery game #{lottery_game.name}: Database error")
        expect(AdminNotificationMailer).to receive(:cycle_completion_error).with(lottery_game, "Database error").and_return(double(deliver_now: true))

        CycleManagementJob.perform_now
      end

      it 'does not change lottery game status on error' do
        original_status = lottery_game.cycle_status

        CycleManagementJob.perform_now

        lottery_game.reload
        expect(lottery_game.cycle_status).to eq(original_status)
      end
    end

    context 'when cycles are still active' do
      let!(:lottery_game) { create(:lottery_game, :with_active_cycles) }

      it 'logs cycle progress' do
        expect(Rails.logger).to receive(:debug).with(/Lottery game #{lottery_game.name}: Cycle \d+\/\d+ \(\d+\.\d+% complete\)/)

        CycleManagementJob.perform_now
      end

      it 'does not complete cycles' do
        original_status = lottery_game.cycle_status

        CycleManagementJob.perform_now

        lottery_game.reload
        expect(lottery_game.cycle_status).to eq(original_status)
      end
    end

    context 'with multiple lottery games' do
      let!(:game1) { create(:lottery_game, :with_active_cycles, name: 'Game 1') }
      let!(:game2) { create(:lottery_game, :with_active_cycles, name: 'Game 2') }
      let!(:game3) { create(:lottery_game, :with_active_cycles, name: 'Game 3') }

      before do
        # Make game1 and game3 completed, keep game2 active
        game1.update!(cycle_start_time: 12.hours.ago)
        game3.update!(cycle_start_time: 12.hours.ago)
      end

      it 'processes all active games' do
        expect_any_instance_of(CycleManagementJob).to receive(:process_lottery_game_cycles).with(game1)
        expect_any_instance_of(CycleManagementJob).to receive(:process_lottery_game_cycles).with(game2)
        expect_any_instance_of(CycleManagementJob).to receive(:process_lottery_game_cycles).with(game3)

        CycleManagementJob.perform_now
      end

      it 'completes only the games with completed cycles' do
        CycleManagementJob.perform_now

        game1.reload
        game2.reload
        game3.reload

        expect(game1.cycle_status).to eq('completed')
        expect(game2.cycle_status).to eq('active')
        expect(game3.cycle_status).to eq('completed')
      end
    end

    context 'with proportional refund strategy' do
      let!(:lottery_game) { create(:lottery_game, :with_active_cycles, :proportional_refund) }
      let!(:ticket1) { create(:ticket, lottery_game: lottery_game, cost: 2.0) }
      let!(:ticket2) { create(:ticket, lottery_game: lottery_game, cost: 3.0) }

      before do
        lottery_game.update!(cycle_start_time: 12.hours.ago)
      end

      it 'processes refunds for all tickets' do
        initial_balance1 = ticket1.user.account_balance
        initial_balance2 = ticket2.user.account_balance

        CycleManagementJob.perform_now

        ticket1.user.reload
        ticket2.user.reload

        expect(ticket1.user.account_balance).to eq(initial_balance1 + 2.0)
        expect(ticket2.user.account_balance).to eq(initial_balance2 + 3.0)
      end

      it 'creates refund payout logs' do
        expect {
          CycleManagementJob.perform_now
        }.to change { PayoutLog.where(payout_type: 'cycle_completion_refund').count }.by(2)
      end
    end

    context 'performance considerations' do
      let!(:many_games) { create_list(:lottery_game, 50, :with_active_cycles) }

      it 'processes all games efficiently' do
        expect {
          CycleManagementJob.perform_now
        }.to change { Rails.logger }.and execute_in_under(10.seconds)
      end

      it 'uses find_each for memory efficiency' do
        expect(LotteryGame).to receive(:find_each).and_call_original
        CycleManagementJob.perform_now
      end
    end
  end

  describe 'job queue configuration' do
    it 'is queued on default queue' do
      expect(CycleManagementJob.queue_name).to eq('default')
    end

    it 'can be enqueued' do
      expect {
        CycleManagementJob.perform_later
      }.to have_enqueued_job(CycleManagementJob)
    end
  end

  describe 'error handling' do
    let!(:lottery_game) { create(:lottery_game, :with_active_cycles) }

    context 'when lottery game is deleted during processing' do
      it 'handles ActiveRecord::RecordNotFound gracefully' do
        allow(LotteryGame).to receive(:where).and_return([ lottery_game ])
        allow(lottery_game).to receive(:cycles_completed?).and_raise(ActiveRecord::RecordNotFound)

        expect {
          CycleManagementJob.perform_now
        }.not_to raise_error
      end
    end

    context 'when database connection is lost' do
      it 'handles database errors gracefully' do
        allow(LotteryGame).to receive(:where).and_raise(ActiveRecord::ConnectionNotEstablished)

        expect {
          CycleManagementJob.perform_now
        }.not_to raise_error
      end
    end
  end

  describe 'integration with ActionJob' do
    it 'inherits from ApplicationJob' do
      expect(CycleManagementJob.superclass).to eq(ApplicationJob)
    end

    it 'can be scheduled to run periodically' do
      # This would typically be configured in a scheduler like cron or whenever gem
      expect(CycleManagementJob).to respond_to(:perform_later)
      expect(CycleManagementJob).to respond_to(:perform_now)
    end
  end
end
