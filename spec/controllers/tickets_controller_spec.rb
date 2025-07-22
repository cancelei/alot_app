require 'rails_helper'

RSpec.describe TicketsController, type: :request do
  let(:user) { create(:user, account_balance: 50.0) }
  let(:lottery_game) { create(:lottery_game) }
  let(:draw) { create(:draw, :upcoming, lottery_game: lottery_game) }

  before do
    sign_in_as_user(user)
  end

  describe 'GET /tickets' do
    let!(:active_ticket) { create(:ticket, user: user, status: 'active') }
    let!(:winning_ticket) { create(:ticket, :winning, user: user) }

    it 'returns successful response' do
      get '/tickets'
      expect(response).to have_http_status(:success)
    end

    it 'assigns user tickets' do
      get '/tickets'
      expect(assigns(:active_tickets)).to include(active_ticket)
      expect(assigns(:winning_tickets)).to include(winning_ticket)
    end

    it 'calculates ticket stats' do
      get '/tickets'
      stats = assigns(:ticket_stats)
      expect(stats[:active_count]).to eq(1)
      expect(stats[:winning_count]).to eq(1)
    end
  end

  describe 'POST /lottery_games/:lottery_game_id/tickets' do
    let(:valid_numbers) { [ 1, 2, 3, 4, 5, 6 ] }
    let(:expected_cost) { 2.0 }

    context 'with valid parameters' do
      let(:valid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: valid_numbers.to_json,
            cost: expected_cost
          }
        }
      end

      it 'creates a new ticket' do
        expect {
          post "/lottery_games/#{lottery_game.id}/tickets", params: valid_params
        }.to change(Ticket, :count).by(1)
      end

      it 'deducts cost from user account' do
        initial_balance = user.account_balance
        post "/lottery_games/#{lottery_game.id}/tickets", params: valid_params
        user.reload
        expect(user.account_balance).to eq(initial_balance - expected_cost)
      end

      it 'creates a payment record' do
        expect {
          post :create, params: valid_params
        }.to change(Payment, :count).by(1)

        payment = Payment.last
        expect(payment.user).to eq(user)
        expect(payment.amount).to eq(expected_cost)
        expect(payment.payment_type).to eq('ticket_purchase')
        expect(payment.status).to eq('completed')
      end

      it 'updates lottery game prize pool' do
        initial_pool = lottery_game.current_prize_pool
        post :create, params: valid_params
        lottery_game.reload
        expect(lottery_game.current_prize_pool).to eq(initial_pool + (expected_cost * 0.7))
      end

      it 'redirects to ticket show page' do
        post :create, params: valid_params
        expect(response).to redirect_to(ticket_path(Ticket.last))
      end

      it 'sets success flash message with selected numbers' do
        post :create, params: valid_params
        expect(flash[:notice]).to include("Your numbers: 1, 2, 3, 4, 5, 6")
      end
    end

    context 'without numbers selected' do
      let(:invalid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: '',
            cost: expected_cost
          }
        }
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Ticket, :count)
      end

      it 'does not deduct from user account' do
        initial_balance = user.account_balance
        post :create, params: invalid_params
        user.reload
        expect(user.account_balance).to eq(initial_balance)
      end

      it 'redirects with error message' do
        post :create, params: invalid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Please select your numbers before purchasing.")
      end
    end

    context 'with invalid JSON numbers' do
      let(:invalid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: 'invalid json',
            cost: expected_cost
          }
        }
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Ticket, :count)
      end

      it 'redirects with error message' do
        post :create, params: invalid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Invalid number selection.")
      end
    end

    context 'with wrong number count' do
      let(:invalid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: [ 1, 2, 3 ].to_json, # Only 3 numbers instead of 6
            cost: expected_cost
          }
        }
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Ticket, :count)
      end

      it 'redirects with specific error message' do
        post :create, params: invalid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Please select exactly #{lottery_game.numbers_to_draw} numbers.")
      end
    end

    context 'with numbers out of range' do
      let(:invalid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: [ 1, 2, 3, 4, 5, 100 ].to_json, # 100 is out of range
            cost: expected_cost
          }
        }
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Ticket, :count)
      end

      it 'redirects with range error message' do
        post :create, params: invalid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Numbers must be between 1 and #{lottery_game.max_number}.")
      end
    end

    context 'with cost mismatch' do
      let(:invalid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: valid_numbers.to_json,
            cost: 10.0 # Wrong cost
          }
        }
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Ticket, :count)
      end

      it 'redirects with price mismatch error' do
        post :create, params: invalid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Price mismatch. Please try again.")
      end
    end

    context 'with insufficient funds' do
      let(:poor_user) { create(:user, :insufficient_funds) }
      let(:valid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: valid_numbers.to_json,
            cost: expected_cost
          }
        }
      end

      before do
        sign_in poor_user
        allow(poor_user).to receive(:can_spend?).and_return(false)
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: valid_params
        }.not_to change(Ticket, :count)
      end

      it 'redirects with insufficient funds error' do
        post :create, params: valid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("Insufficient funds or spending limit exceeded.")
      end
    end

    context 'with no upcoming draws' do
      let(:valid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: valid_numbers.to_json,
            cost: expected_cost
          }
        }
      end

      before do
        draw.update!(draw_date: 1.hour.ago) # Make draw past
      end

      it 'does not create a ticket' do
        expect {
          post :create, params: valid_params
        }.not_to change(Ticket, :count)
      end

      it 'redirects with no draws error' do
        post :create, params: valid_params
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to eq("No upcoming draws available.")
      end
    end

    context 'when database error occurs' do
      let(:valid_params) do
        {
          lottery_game_id: lottery_game.id,
          ticket: {
            numbers: valid_numbers.to_json,
            cost: expected_cost
          }
        }
      end

      before do
        allow(Ticket).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Ticket.new))
      end

      it 'rolls back transaction and shows error' do
        initial_balance = user.account_balance
        post :create, params: valid_params
        user.reload
        expect(user.account_balance).to eq(initial_balance) # No deduction due to rollback
        expect(response).to redirect_to(lottery_game_path(lottery_game))
        expect(flash[:alert]).to include("Failed to purchase ticket")
      end
    end
  end

  describe 'POST #quick_pick' do
    let(:quick_pick_params) do
      {
        lottery_game_id: lottery_game.id,
        multi_draw_count: 1
      }
    end

    it 'generates random numbers' do
      post :quick_pick, params: quick_pick_params
      ticket = Ticket.last
      expect(ticket.numbers.length).to eq(lottery_game.numbers_to_draw)
      expect(ticket.numbers.all? { |n| n.between?(1, lottery_game.max_number) }).to be_truthy
    end

    it 'creates ticket with quick pick numbers' do
      expect {
        post :quick_pick, params: quick_pick_params
      }.to change(Ticket, :count).by(1)
    end

    it 'redirects to ticket show page on success' do
      post :quick_pick, params: quick_pick_params
      expect(response).to redirect_to(ticket_path(Ticket.last))
      expect(flash[:notice]).to eq("Quick Pick ticket purchased successfully!")
    end
  end

  describe 'private methods' do
    let(:controller_instance) { TicketsController.new }

    describe '#calculate_ticket_cost' do
      before do
        controller_instance.instance_variable_set(:@lottery_game, lottery_game)
      end

      it 'calculates base cost for minimum numbers' do
        cost = controller_instance.send(:calculate_ticket_cost, lottery_game.numbers_to_draw)
        expect(cost).to eq(lottery_game.ticket_price)
      end

      it 'increases cost for additional numbers' do
        base_cost = controller_instance.send(:calculate_ticket_cost, lottery_game.numbers_to_draw)
        higher_cost = controller_instance.send(:calculate_ticket_cost, lottery_game.numbers_to_draw + 1)
        expect(higher_cost).to be > base_cost
      end
    end

    describe '#generate_quick_pick_numbers' do
      it 'generates correct number of unique numbers' do
        numbers = controller_instance.send(:generate_quick_pick_numbers, lottery_game)
        expect(numbers.length).to eq(lottery_game.numbers_to_draw)
        expect(numbers.uniq.length).to eq(lottery_game.numbers_to_draw) # All unique
      end

      it 'generates numbers within valid range' do
        numbers = controller_instance.send(:generate_quick_pick_numbers, lottery_game)
        expect(numbers.all? { |n| n.between?(1, lottery_game.max_number) }).to be_truthy
      end

      it 'returns sorted numbers' do
        numbers = controller_instance.send(:generate_quick_pick_numbers, lottery_game)
        expect(numbers).to eq(numbers.sort)
      end
    end
  end

  context 'authentication and authorization' do
    context 'when user is not signed in' do
      before { sign_out user }

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user cannot purchase tickets' do
      let(:unverified_user) { create(:user, :unverified) }

      before do
        sign_in unverified_user
        allow(unverified_user).to receive(:can_purchase_tickets?).and_return(false)
      end

      it 'redirects to dashboard with error' do
        get :index
        expect(response).to redirect_to(dashboard_path)
        expect(flash[:alert]).to eq("You must complete verification to purchase tickets.")
      end
    end
  end
end
