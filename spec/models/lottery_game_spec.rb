require 'rails_helper'

RSpec.describe LotteryGame, type: :model do
  let(:lottery_game) { create(:lottery_game) }

  describe 'validations' do
    it 'validates presence of required fields' do
      expect(lottery_game).to be_valid
    end

    it 'validates cycle management fields' do
      lottery_game.cycle_length_minutes = nil
      expect(lottery_game).not_to be_valid
      expect(lottery_game.errors[:cycle_length_minutes]).to include("can't be blank")

      lottery_game.cycle_length_minutes = -1
      expect(lottery_game).not_to be_valid
      expect(lottery_game.errors[:cycle_length_minutes]).to include("must be greater than 0")

      lottery_game.cycle_length_minutes = 60
      lottery_game.total_cycles = nil
      expect(lottery_game).not_to be_valid
      expect(lottery_game.errors[:total_cycles]).to include("can't be blank")

      lottery_game.total_cycles = 0
      expect(lottery_game).not_to be_valid
      expect(lottery_game.errors[:total_cycles]).to include("must be greater than 0")

      lottery_game.total_cycles = 10
      lottery_game.payout_strategy = "invalid_strategy"
      expect(lottery_game).not_to be_valid
      expect(lottery_game.errors[:payout_strategy]).to include("is not included in the list")

      lottery_game.payout_strategy = "winner_takes_all"
      expect(lottery_game).to be_valid
    end

    it 'validates payout strategy options' do
      valid_strategies = %w[winner_takes_all proportional_refund admin_discretion]

      valid_strategies.each do |strategy|
        lottery_game.payout_strategy = strategy
        expect(lottery_game).to be_valid
      end
    end
  end

  describe 'cycle management methods' do
    let(:lottery_game) { create(:lottery_game, :with_active_cycles) }

    describe '#current_cycle_number' do
      it 'returns 1 when no cycle_start_time is set' do
        lottery_game.cycle_start_time = nil
        expect(lottery_game.current_cycle_number).to eq(1)
      end

      it 'calculates current cycle based on elapsed time' do
        # 2 hours ago, with 60-minute cycles = cycle 3
        expect(lottery_game.current_cycle_number).to eq(3)
      end

      it 'does not exceed total_cycles' do
        lottery_game.cycle_start_time = 20.hours.ago
        expect(lottery_game.current_cycle_number).to eq(lottery_game.total_cycles)
      end
    end

    describe '#cycle_progress_percentage' do
      it 'returns 0 when no cycle_start_time is set' do
        lottery_game.cycle_start_time = nil
        expect(lottery_game.cycle_progress_percentage).to eq(0)
      end

      it 'calculates progress percentage correctly' do
        # 2 hours into 10 cycles of 60 minutes each = 2/600 * 100 = 0.33%
        expected_percentage = (2.0 / 10.0 * 100).round(2)
        expect(lottery_game.cycle_progress_percentage).to eq(expected_percentage)
      end

      it 'does not exceed 100%' do
        lottery_game.cycle_start_time = 20.hours.ago
        expect(lottery_game.cycle_progress_percentage).to eq(100.0)
      end
    end

    describe '#time_remaining_in_current_cycle' do
      it 'returns 0 when no cycle_start_time is set' do
        lottery_game.cycle_start_time = nil
        expect(lottery_game.time_remaining_in_current_cycle).to eq(0)
      end

      it 'calculates time remaining in current cycle' do
        # Started 2 hours ago, in cycle 3, so cycle 3 ends at 3 hours from start
        # Time remaining = 1 hour = 3600 seconds
        expect(lottery_game.time_remaining_in_current_cycle).to be_within(60).of(3600)
      end

      it 'returns 0 when cycle is completed' do
        lottery_game.cycle_start_time = 12.hours.ago
        expect(lottery_game.time_remaining_in_current_cycle).to eq(0)
      end
    end

    describe '#total_cycle_time_remaining' do
      it 'calculates total time remaining across all cycles' do
        # 10 cycles * 60 minutes = 600 minutes = 36000 seconds
        # Started 2 hours ago = 7200 seconds ago
        # Remaining = 36000 - 7200 = 28800 seconds
        expect(lottery_game.total_cycle_time_remaining).to be_within(60).of(28800)
      end

      it 'returns 0 when all cycles are completed' do
        lottery_game.cycle_start_time = 12.hours.ago
        expect(lottery_game.total_cycle_time_remaining).to eq(0)
      end
    end

    describe '#cycles_completed?' do
      it 'returns false when cycles are still active' do
        expect(lottery_game.cycles_completed?).to be_falsey
      end

      it 'returns true when all cycles are completed' do
        lottery_game.cycle_start_time = 12.hours.ago
        expect(lottery_game.cycles_completed?).to be_truthy
      end
    end

    describe '#start_cycles!' do
      let(:lottery_game) { create(:lottery_game) }

      it 'sets cycle_start_time and status to active' do
        freeze_time do
          lottery_game.start_cycles!
          expect(lottery_game.cycle_start_time).to eq(Time.current)
          expect(lottery_game.cycle_status).to eq('active')
        end
      end
    end

    describe '#complete_cycles!' do
      context 'with winner_takes_all strategy' do
        let(:lottery_game) { create(:lottery_game, :with_active_cycles, payout_strategy: 'winner_takes_all') }
        let!(:winning_ticket) { create(:ticket, :winning, lottery_game: lottery_game, prize_amount: 50.0) }
        let!(:losing_ticket) { create(:ticket, lottery_game: lottery_game) }

        before do
          lottery_game.cycle_start_time = 12.hours.ago # Completed cycles
        end

        it 'processes winner takes all payout' do
          expect { lottery_game.complete_cycles! }.to change { PayoutLog.count }.by(1)

          payout_log = PayoutLog.last
          expect(payout_log.user).to eq(winning_ticket.user)
          expect(payout_log.payout_type).to eq('cycle_completion_winner_takes_all')
          expect(lottery_game.cycle_status).to eq('completed')
        end
      end

      context 'with proportional_refund strategy' do
        let(:lottery_game) { create(:lottery_game, :with_active_cycles, payout_strategy: 'proportional_refund') }
        let!(:ticket1) { create(:ticket, lottery_game: lottery_game, cost: 2.0) }
        let!(:ticket2) { create(:ticket, lottery_game: lottery_game, cost: 3.0) }

        before do
          lottery_game.cycle_start_time = 12.hours.ago # Completed cycles
        end

        it 'processes proportional refunds' do
          initial_balance1 = ticket1.user.account_balance
          initial_balance2 = ticket2.user.account_balance

          expect { lottery_game.complete_cycles! }.to change { PayoutLog.count }.by(2)

          ticket1.user.reload
          ticket2.user.reload

          expect(ticket1.user.account_balance).to eq(initial_balance1 + 2.0)
          expect(ticket2.user.account_balance).to eq(initial_balance2 + 3.0)
          expect(lottery_game.cycle_status).to eq('completed')
        end
      end

      context 'with admin_discretion strategy' do
        let(:lottery_game) { create(:lottery_game, :with_active_cycles, payout_strategy: 'admin_discretion') }

        before do
          lottery_game.cycle_start_time = 12.hours.ago # Completed cycles
        end

        it 'sets status to pending_admin_review' do
          lottery_game.complete_cycles!
          expect(lottery_game.cycle_status).to eq('pending_admin_review')
        end
      end

      it 'does not complete cycles when not ready' do
        expect { lottery_game.complete_cycles! }.not_to change { lottery_game.cycle_status }
      end
    end
  end

  describe 'payout processing methods' do
    let(:lottery_game) { create(:lottery_game, :with_active_cycles) }

    describe '#process_winner_takes_all_payout' do
      let!(:winning_ticket1) { create(:ticket, :winning, lottery_game: lottery_game, prize_amount: 100.0, cost: 2.0) }
      let!(:winning_ticket2) { create(:ticket, :winning, lottery_game: lottery_game, prize_amount: 50.0, cost: 3.0) }
      let!(:losing_ticket) { create(:ticket, lottery_game: lottery_game, cost: 2.0) }

      it 'awards total invested amount to biggest winner' do
        total_invested = 7.0 # 2 + 3 + 2

        lottery_game.send(:process_winner_takes_all_payout)

        winning_ticket1.reload
        expect(winning_ticket1.prize_amount).to eq(100.0 + total_invested)
        expect(winning_ticket1.payout_status).to eq('pending')

        payout_log = PayoutLog.find_by(ticket: winning_ticket1, payout_type: 'cycle_completion_winner_takes_all')
        expect(payout_log).to be_present
        expect(payout_log.amount).to eq(total_invested)
      end

      it 'processes refund when no winners exist' do
        Ticket.update_all(status: 'lost')

        expect(lottery_game).to receive(:process_proportional_refund)
        lottery_game.send(:process_winner_takes_all_payout)
      end
    end

    describe '#process_proportional_refund' do
      let!(:ticket1) { create(:ticket, lottery_game: lottery_game, cost: 2.0) }
      let!(:ticket2) { create(:ticket, lottery_game: lottery_game, cost: 3.0) }

      it 'refunds full cost to all ticket holders' do
        initial_balance1 = ticket1.user.account_balance
        initial_balance2 = ticket2.user.account_balance

        lottery_game.send(:process_proportional_refund)

        ticket1.user.reload
        ticket2.user.reload
        ticket1.reload
        ticket2.reload

        expect(ticket1.user.account_balance).to eq(initial_balance1 + 2.0)
        expect(ticket2.user.account_balance).to eq(initial_balance2 + 3.0)
        expect(ticket1.payout_status).to eq('refunded')
        expect(ticket2.payout_status).to eq('refunded')

        refund_logs = PayoutLog.where(payout_type: 'cycle_completion_refund')
        expect(refund_logs.count).to eq(2)
        expect(refund_logs.sum(:amount)).to eq(5.0)
      end
    end
  end

  describe 'scopes and class methods' do
    let!(:active_game) { create(:lottery_game, is_active: true) }
    let!(:inactive_game) { create(:lottery_game, is_active: false) }
    let!(:rapid_game) { create(:lottery_game, game_type: 'rapid') }
    let!(:daily_game) { create(:lottery_game, game_type: 'daily') }

    it 'filters active games' do
      expect(LotteryGame.active).to include(active_game)
      expect(LotteryGame.active).not_to include(inactive_game)
    end

    it 'filters by game type' do
      expect(LotteryGame.rapid).to include(rapid_game)
      expect(LotteryGame.rapid).not_to include(daily_game)
    end
  end
end
