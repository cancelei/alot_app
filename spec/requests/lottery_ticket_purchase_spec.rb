require 'rails_helper'

RSpec.describe "Lottery Ticket Purchase Integration", type: :request do
  let(:user) { create(:user, account_balance: 100.0) }
  let(:lottery_game) { create(:lottery_game) }
  let(:draw) { create(:draw, :upcoming, lottery_game: lottery_game) }

  before do
    sign_in user
  end

  describe "Complete ticket purchase flow" do
    context "successful purchase with number selection" do
      let(:valid_numbers) { [ 1, 2, 3, 4, 5, 6 ] }
      let(:expected_cost) { 2.0 }

      it "prevents unfair losses by requiring number selection first" do
        # Step 1: Visit lottery game page
        get lottery_game_path(lottery_game)
        expect(response).to have_http_status(:success)

        # Verify interactive number picker data is available
        expect(response.body).to include('data-controller="number-picker"')
        expect(response.body).to include("max-number=\"#{lottery_game.max_number}\"")
        expect(response.body).to include("numbers-to-draw=\"#{lottery_game.numbers_to_draw}\"")

        # Step 2: Attempt purchase without numbers (should fail)
        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: '',
            cost: expected_cost
          }
        }

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Please select your numbers before purchasing.")
        expect(Ticket.count).to eq(0) # No ticket created

        user.reload
        expect(user.account_balance).to eq(100.0) # No money deducted

        # Step 3: Purchase with valid numbers (should succeed)
        expect {
          post lottery_game_tickets_path(lottery_game), params: {
            ticket: {
              numbers: valid_numbers.to_json,
              cost: expected_cost
            }
          }
        }.to change { Ticket.count }.by(1)
          .and change { Payment.count }.by(1)

        # Verify ticket creation
        ticket = Ticket.last
        expect(ticket.user).to eq(user)
        expect(ticket.lottery_game).to eq(lottery_game)
        expect(ticket.numbers).to eq(valid_numbers)
        expect(ticket.cost).to eq(expected_cost)
        expect(ticket.status).to eq('active')

        # Verify payment processing
        payment = Payment.last
        expect(payment.user).to eq(user)
        expect(payment.ticket).to eq(ticket)
        expect(payment.amount).to eq(expected_cost)
        expect(payment.status).to eq('completed')

        # Verify account balance deduction
        user.reload
        expect(user.account_balance).to eq(98.0)

        # Verify prize pool update
        lottery_game.reload
        expected_pool_increase = expected_cost * 0.7
        expect(lottery_game.current_prize_pool).to be >= (lottery_game.jackpot_seed + expected_pool_increase)

        # Verify redirect and success message
        expect(response).to redirect_to(ticket_path(ticket))
        expect(flash[:notice]).to include("Ticket purchased successfully!")
        expect(flash[:notice]).to include("Your numbers: 1, 2, 3, 4, 5, 6")
      end
    end

    context "security validations prevent manipulation" do
      it "prevents cost manipulation" do
        # Attempt to submit lower cost than calculated
        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 6 ].to_json,
            cost: 0.50 # Much lower than expected 2.0
          }
        }

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Price mismatch. Please try again.")
        expect(Ticket.count).to eq(0)

        user.reload
        expect(user.account_balance).to eq(100.0) # No deduction
      end

      it "prevents number range manipulation" do
        # Attempt to submit numbers outside valid range
        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 999 ].to_json, # 999 is out of range
            cost: 2.0
          }
        }

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Numbers must be between 1 and #{lottery_game.max_number}.")
        expect(Ticket.count).to eq(0)
      end

      it "prevents invalid JSON injection" do
        # Attempt to submit malformed JSON
        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: '{"malicious": "code"}',
            cost: 2.0
          }
        }

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Invalid number selection.")
        expect(Ticket.count).to eq(0)
      end
    end

    context "spending limits and account protection" do
      let(:poor_user) { create(:user, account_balance: 1.0) }

      before do
        sign_in poor_user
        allow(poor_user).to receive(:can_spend?).and_return(false)
      end

      it "prevents purchases when user cannot afford ticket" do
        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 6 ].to_json,
            cost: 2.0
          }
        }

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Insufficient funds or spending limit exceeded.")
        expect(Ticket.count).to eq(0)

        poor_user.reload
        expect(poor_user.account_balance).to eq(1.0) # No deduction
      end
    end

    context "transaction safety and rollback" do
      it "rolls back all changes if any step fails" do
        # Mock a failure during ticket creation
        allow(Ticket).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Ticket.new))

        initial_balance = user.account_balance
        initial_ticket_count = Ticket.count
        initial_payment_count = Payment.count

        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 6 ].to_json,
            cost: 2.0
          }
        }

        # Verify rollback occurred
        user.reload
        expect(user.account_balance).to eq(initial_balance) # Balance restored
        expect(Ticket.count).to eq(initial_ticket_count) # No ticket created
        expect(Payment.count).to eq(initial_payment_count) # No payment created

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to include("Failed to purchase ticket")
      end
    end

    context "quick pick functionality" do
      it "generates valid random numbers and creates ticket" do
        expect {
          post quick_pick_lottery_game_tickets_path(lottery_game), params: {
            multi_draw_count: 1
          }
        }.to change { Ticket.count }.by(1)

        ticket = Ticket.last
        expect(ticket.numbers.length).to eq(lottery_game.numbers_to_draw)
        expect(ticket.numbers.all? { |n| n.between?(1, lottery_game.max_number) }).to be_truthy
        expect(ticket.numbers.uniq.length).to eq(lottery_game.numbers_to_draw) # All unique
        expect(ticket.numbers).to eq(ticket.numbers.sort) # Sorted

        expect(response).to redirect_to(ticket_path(ticket))
        expect(flash[:notice]).to eq("Quick Pick ticket purchased successfully!")
      end
    end
  end

  describe "User verification requirements" do
    let(:unverified_user) { create(:user, :unverified) }

    before do
      sign_in unverified_user
      allow(unverified_user).to receive(:fully_verified?).and_return(false)
    end

    it "prevents unverified users from accessing lottery games" do
      get lottery_game_path(lottery_game)
      expect(response).to redirect_to(onboarding_path)
      expect(flash[:alert]).to eq("Please complete your account verification to play lottery games.")
    end

    it "prevents unverified users from purchasing tickets" do
      post lottery_game_tickets_path(lottery_game), params: {
        ticket: {
          numbers: [ 1, 2, 3, 4, 5, 6 ].to_json,
          cost: 2.0
        }
      }

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to eq("You must complete verification to purchase tickets.")
    end
  end

  describe "Game availability checks" do
    context "when lottery game is inactive" do
      let(:inactive_game) { create(:lottery_game, is_active: false) }

      it "shows game but prevents purchases" do
        get lottery_game_path(inactive_game)
        expect(response).to have_http_status(:success)

        # Purchase should fail
        post lottery_game_tickets_path(inactive_game), params: {
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 6 ].to_json,
            cost: 2.0
          }
        }

        # Should redirect with appropriate error
        expect(Ticket.count).to eq(0)
      end
    end

    context "when no upcoming draws exist" do
      before do
        draw.update!(draw_date: 1.hour.ago) # Make draw past
      end

      it "prevents ticket purchases" do
        post lottery_game_tickets_path(lottery_game), params: {
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 6 ].to_json,
            cost: 2.0
          }
        }

        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("No upcoming draws available.")
        expect(Ticket.count).to eq(0)
      end
    end
  end

  describe "Real-time data for interactive UI" do
    it "provides necessary data for number picker JavaScript" do
      get lottery_game_path(lottery_game)

      # Check that the response includes data attributes for the Stimulus controller
      expect(response.body).to include('data-controller="number-picker"')
      expect(response.body).to include("data-number-picker-max-number-value=\"#{lottery_game.max_number}\"")
      expect(response.body).to include("data-number-picker-numbers-to-draw-value=\"#{lottery_game.numbers_to_draw}\"")
      expect(response.body).to include("data-number-picker-base-cost-value=\"#{lottery_game.ticket_price}\"")
      expect(response.body).to include("data-number-picker-user-balance-value=\"#{user.account_balance}\"")
    end

    it "shows current prize pool and time until draw" do
      get lottery_game_path(lottery_game)

      expect(response.body).to include(lottery_game.current_prize_pool.to_s)
      expect(response.body).to include("Time until draw")
    end
  end
end
