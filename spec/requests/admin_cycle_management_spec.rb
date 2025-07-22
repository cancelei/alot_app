require 'rails_helper'

RSpec.describe "Admin Cycle Management Integration", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let(:lottery_game) { create(:lottery_game, cycle_length_minutes: 60, total_cycles: 10, payout_strategy: 'winner_takes_all') }

  before do
    sign_in admin_user
  end

  describe "Complete cycle management workflow" do
    context "starting and completing cycles with winner takes all" do
      let!(:winning_ticket) { create(:ticket, :winning, lottery_game: lottery_game, prize_amount: 50.0, cost: 2.0) }
      let!(:losing_ticket) { create(:ticket, lottery_game: lottery_game, cost: 3.0) }

      it "manages complete cycle lifecycle with proper payouts" do
        # Step 1: View lottery game admin page
        get admin_lottery_game_path(lottery_game)
        expect(response).to have_http_status(:success)

        # Verify cycle management UI is present
        expect(response.body).to include("Cycle Management")
        expect(response.body).to include("Not Started")
        expect(response.body).to include("60 minutes") # cycle length
        expect(response.body).to include("10") # total cycles
        expect(response.body).to include("Winner takes all") # payout strategy

        # Step 2: Start cycles
        freeze_time do
          expect {
            post start_cycles_admin_lottery_game_path(lottery_game)
          }.to change { lottery_game.reload.cycle_status }.from(nil).to('active')

          expect(lottery_game.cycle_start_time).to eq(Time.current)
          expect(response).to redirect_to(admin_lottery_game_path(lottery_game))
          expect(flash[:notice]).to eq("Lottery game cycles have been started.")
        end

        # Step 3: View active cycles progress
        get admin_lottery_game_path(lottery_game)
        expect(response.body).to include("Active Cycles")
        expect(response.body).to include("Progress")
        expect(response.body).to include("Current Cycle")
        expect(response.body).to include("Time Remaining")

        # Step 4: Fast forward to cycle completion
        travel 11.hours do # Beyond 10 cycles of 60 minutes each
          lottery_game.reload
          expect(lottery_game.cycles_completed?).to be_truthy

          # Complete cycles manually (simulating background job or admin action)
          expect {
            post complete_cycles_admin_lottery_game_path(lottery_game)
          }.to change { PayoutLog.count }.by(1)

          lottery_game.reload
          expect(lottery_game.cycle_status).to eq('completed')
          expect(response).to redirect_to(admin_lottery_game_path(lottery_game))
          expect(flash[:notice]).to eq("Lottery game cycles have been completed and payouts processed.")

          # Verify winner takes all payout
          payout_log = PayoutLog.last
          expect(payout_log.user).to eq(winning_ticket.user)
          expect(payout_log.payout_type).to eq('cycle_completion_winner_takes_all')
          expect(payout_log.amount).to eq(5.0) # 2.0 + 3.0 total invested

          # Verify winning ticket updated
          winning_ticket.reload
          expect(winning_ticket.prize_amount).to eq(55.0) # 50.0 + 5.0
          expect(winning_ticket.payout_status).to eq('pending')
        end

        # Step 5: View completed cycles
        get admin_lottery_game_path(lottery_game)
        expect(response.body).to include("Completed")
        expect(response.body).not_to include("Start Cycles") # Button should not be visible for completed
      end
    end

    context "proportional refund strategy" do
      let(:refund_game) { create(:lottery_game, :proportional_refund, cycle_length_minutes: 30, total_cycles: 5) }
      let!(:ticket1) { create(:ticket, lottery_game: refund_game, cost: 2.0) }
      let!(:ticket2) { create(:ticket, lottery_game: refund_game, cost: 3.0) }

      it "processes proportional refunds correctly" do
        # Start cycles
        post start_cycles_admin_lottery_game_path(refund_game)
        refund_game.reload
        expect(refund_game.cycle_status).to eq('active')

        # Fast forward to completion
        travel 3.hours do # Beyond 5 cycles of 30 minutes each
          initial_balance1 = ticket1.user.account_balance
          initial_balance2 = ticket2.user.account_balance

          expect {
            post complete_cycles_admin_lottery_game_path(refund_game)
          }.to change { PayoutLog.where(payout_type: 'cycle_completion_refund').count }.by(2)

          # Verify refunds processed
          ticket1.user.reload
          ticket2.user.reload

          expect(ticket1.user.account_balance).to eq(initial_balance1 + 2.0)
          expect(ticket2.user.account_balance).to eq(initial_balance2 + 3.0)

          # Verify tickets marked as refunded
          ticket1.reload
          ticket2.reload
          expect(ticket1.payout_status).to eq('refunded')
          expect(ticket2.payout_status).to eq('refunded')
        end
      end
    end

    context "admin discretion strategy" do
      let(:discretion_game) { create(:lottery_game, payout_strategy: 'admin_discretion', cycle_length_minutes: 45, total_cycles: 8) }

      it "requires manual admin review and completion" do
        # Start cycles
        post start_cycles_admin_lottery_game_path(discretion_game)

        # Fast forward to completion
        travel 7.hours do # Beyond 8 cycles of 45 minutes each
          post complete_cycles_admin_lottery_game_path(discretion_game)

          discretion_game.reload
          expect(discretion_game.cycle_status).to eq('pending_admin_review')

          # View admin page - should show manual completion option
          get admin_lottery_game_path(discretion_game)
          expect(response.body).to include("Needs Review")
          expect(response.body).to include("Manual Complete")

          # Manually complete
          post complete_cycles_admin_lottery_game_path(discretion_game)

          discretion_game.reload
          expect(discretion_game.cycle_status).to eq('completed')
          expect(flash[:notice]).to eq("Lottery game cycles manually completed.")
        end
      end
    end
  end

  describe "Cycle management validation and security" do
    context "preventing duplicate cycle starts" do
      let(:active_game) { create(:lottery_game, :with_active_cycles) }

      it "prevents starting cycles when already active" do
        original_start_time = active_game.cycle_start_time

        post start_cycles_admin_lottery_game_path(active_game)

        active_game.reload
        expect(active_game.cycle_start_time).to eq(original_start_time)
        expect(response).to redirect_to(admin_lottery_game_path(active_game))
        expect(flash[:alert]).to eq("Cannot start cycles - game already has active cycles.")
      end
    end

    context "preventing premature cycle completion" do
      let(:active_game) { create(:lottery_game, :with_active_cycles) }

      it "prevents completing cycles before they're finished" do
        expect(active_game.cycles_completed?).to be_falsey

        post complete_cycles_admin_lottery_game_path(active_game)

        active_game.reload
        expect(active_game.cycle_status).to eq('active') # Unchanged
        expect(response).to redirect_to(admin_lottery_game_path(active_game))
        expect(flash[:alert]).to eq("Cannot complete cycles at this time.")
      end
    end

    context "restarting completed cycles" do
      let(:completed_game) { create(:lottery_game, :with_completed_cycles) }

      it "allows starting new cycles after completion" do
        freeze_time do
          post start_cycles_admin_lottery_game_path(completed_game)

          completed_game.reload
          expect(completed_game.cycle_status).to eq('active')
          expect(completed_game.cycle_start_time).to eq(Time.current)
          expect(flash[:notice]).to eq("Lottery game cycles have been started.")
        end
      end
    end
  end

  describe "Admin UI cycle progress display" do
    let(:active_game) { create(:lottery_game, :with_active_cycles, cycle_length_minutes: 60, total_cycles: 10) }

    before do
      # Set start time to 2 hours ago for predictable progress calculations
      active_game.update!(cycle_start_time: 2.hours.ago)
    end

    it "displays accurate cycle progress information" do
      get admin_lottery_game_path(active_game)

      # Should show progress bar and statistics
      expect(response.body).to include("Progress")
      expect(response.body).to include("Current Cycle")
      expect(response.body).to include("Time Remaining")

      # Progress should be around 20% (2 hours out of 10 hours total)
      expected_progress = (2.0 / 10.0 * 100).round(2)
      expect(response.body).to include("#{expected_progress}%")

      # Current cycle should be 3 (2 hours elapsed with 60-minute cycles)
      expect(response.body).to include("3 / 10")
    end

    it "shows completion button when cycles are finished" do
      # Fast forward to completion
      travel 11.hours do
        get admin_lottery_game_path(active_game)
        expect(response.body).to include("Complete Cycles")
        expect(response.body).not_to include("Start Cycles")
      end
    end
  end

  describe "Authorization and access control" do
    context "regular user access" do
      before do
        sign_out admin_user
        sign_in regular_user
      end

      it "denies access to cycle management actions" do
        post start_cycles_admin_lottery_game_path(lottery_game)
        expect(response).to have_http_status(:redirect)
        expect(response).not_to redirect_to(admin_lottery_game_path(lottery_game))
      end

      it "denies access to admin lottery game views" do
        get admin_lottery_game_path(lottery_game)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "unauthenticated access" do
      before { sign_out admin_user }

      it "redirects to sign in" do
        post start_cycles_admin_lottery_game_path(lottery_game)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "Error handling and edge cases" do
    context "when lottery game doesn't exist" do
      it "handles missing lottery game gracefully" do
        expect {
          post start_cycles_admin_lottery_game_path(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when database errors occur during cycle completion" do
      let(:active_game) { create(:lottery_game, :with_active_cycles) }

      before do
        active_game.update!(cycle_start_time: 12.hours.ago) # Make cycles completed
        allow(active_game).to receive(:complete_cycles!).and_raise(StandardError.new("Database error"))
        allow(LotteryGame).to receive(:find).and_return(active_game)
      end

      it "handles errors gracefully" do
        post complete_cycles_admin_lottery_game_path(active_game)

        # Should still redirect but with error handling
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "Background job integration simulation" do
    let(:multiple_games) do
      [
        create(:lottery_game, :with_active_cycles, name: 'Game 1'),
        create(:lottery_game, :with_active_cycles, name: 'Game 2'),
        create(:lottery_game, :with_active_cycles, name: 'Game 3')
      ]
    end

    before do
      # Make some games completed
      multiple_games[0].update!(cycle_start_time: 12.hours.ago)
      multiple_games[2].update!(cycle_start_time: 12.hours.ago)
    end

    it "simulates background job processing multiple games" do
      # This simulates what CycleManagementJob would do
      LotteryGame.where(cycle_status: 'active').find_each do |game|
        if game.cycles_completed?
          game.complete_cycles!
        end
      end

      multiple_games.each(&:reload)

      expect(multiple_games[0].cycle_status).to eq('completed')
      expect(multiple_games[1].cycle_status).to eq('active')
      expect(multiple_games[2].cycle_status).to eq('completed')
    end
  end
end
