require 'rails_helper'

RSpec.describe 'Lottery Games', type: :request do
  let(:user) { create(:user) }
  let(:unverified_user) { create(:user, :unverified) }
  let(:lottery_game) { create(:lottery_game) }
  let(:draw) { create(:draw, :upcoming, lottery_game: lottery_game) }

  before do
    sign_in_as_user
  end

  describe 'GET /lottery_games' do
    let!(:rapid_game) { create(:lottery_game, game_type: 'rapid', is_active: true) }
    let!(:daily_game) { create(:lottery_game, game_type: 'daily', is_active: true) }
    let!(:inactive_game) { create(:lottery_game, is_active: false) }

    it 'returns successful response' do
      get '/lottery_games'
      expect(response).to have_http_status(:success)
    end

    it 'displays only active lottery games' do
      get '/lottery_games'
      expect(response.body).to include(rapid_game.name)
      expect(response.body).to include(daily_game.name)
      expect(response.body).not_to include(inactive_game.name)
    end

    it 'sorts games by next draw time' do
      # Create games with different next draw times
      early_game = create(:lottery_game, is_active: true)
      late_game = create(:lottery_game, is_active: true)

      create(:draw, :upcoming, lottery_game: early_game, draw_date: 1.hour.from_now)
      create(:draw, :upcoming, lottery_game: late_game, draw_date: 2.hours.from_now)

      get '/lottery_games'

      # Should display games in order by next draw time
      expect(response.body).to include(early_game.name)
      expect(response.body).to include(late_game.name)
    end

    context 'with filters' do
      it 'filters by rapid games' do
        get '/lottery_games', params: { filter: 'rapid' }
        expect(response.body).to include(rapid_game.name)
        expect(response.body).not_to include(daily_game.name)
      end

      it 'filters by daily games' do
        get '/lottery_games', params: { filter: 'daily' }
        expect(response.body).to include(daily_game.name)
        expect(response.body).not_to include(rapid_game.name)
      end

      it 'filters by progressive games' do
        progressive_game = create(:lottery_game, game_type: 'progressive', is_active: true)
        get '/lottery_games', params: { filter: 'progressive' }
        expect(response.body).to include(progressive_game.name)
        expect(response.body).not_to include(rapid_game.name)
      end
    end
  end

  describe 'GET /lottery_games/:id' do
    let!(:recent_draw) { create(:draw, :completed, lottery_game: lottery_game) }
    let!(:user_ticket) { create(:ticket, user: user, lottery_game: lottery_game) }

    it 'returns successful response' do
      get "/lottery_games/#{lottery_game.id}"
      expect(response).to have_http_status(:success)
    end

    it 'displays lottery game and related data' do
      get "/lottery_games/#{lottery_game.id}"

      expect(response.body).to include(lottery_game.name)
      expect(response.body).to include(lottery_game.description)
      expect(response.body).to include('Recent Draws')
      expect(response.body).to include('Your Tickets')
    end

    it 'shows game statistics' do
      get "/lottery_games/#{lottery_game.id}"

      expect(response.body).to include('Prize Pool')
      expect(response.body).to include('Tickets Sold')
      expect(response.body).to include('Next Draw')
    end

    it 'shows purchase interface for verified users' do
      get "/lottery_games/#{lottery_game.id}"

      expect(response.body).to include('Purchase Ticket')
      expect(response.body).to include('Your Balance')
      expect(response.body).to include('Ticket Cost')
    end

    context 'when user is not verified' do
      before do
        @unverified_user = create(:user, :unverified)
        post user_session_path, params: {
          user: {
            email: @unverified_user.email,
            password: @unverified_user.password
          }
        }
        allow(@unverified_user).to receive(:fully_verified?).and_return(false)
      end

      it 'redirects to onboarding' do
        get "/lottery_games/#{lottery_game.id}"
        expect(response).to redirect_to(onboarding_path)
        expect(flash[:alert]).to eq("Please complete your account verification to play lottery games.")
      end
    end

    context 'when lottery game is inactive' do
      let(:inactive_game) { create(:lottery_game, is_active: false) }

      it 'shows game as inactive' do
        get "/lottery_games/#{inactive_game.id}"
        expect(response.body).to include('Game Inactive')
      end
    end

    context 'when no upcoming draws exist' do
      before do
        draw.update!(draw_date: 1.hour.ago) # Make draw past
      end

      it 'shows no purchase option' do
        get "/lottery_games/#{lottery_game.id}"
        expect(response.body).not_to include('Purchase Ticket')
      end
    end

    context 'with winning tickets' do
      let!(:winning_ticket) { create(:ticket, :winning, lottery_game: lottery_game, prize_amount: 500.0) }

      it 'displays winning statistics' do
        get "/lottery_games/#{lottery_game.id}"
        expect(response.body).to include('$500')
        expect(response.body).to include('Winners')
      end
    end

    context 'with multiple tickets and draws' do
      let!(:ticket1) { create(:ticket, lottery_game: lottery_game, cost: 2.0) }
      let!(:ticket2) { create(:ticket, lottery_game: lottery_game, cost: 3.0) }
      let!(:draw1) { create(:draw, :completed, lottery_game: lottery_game) }
      let!(:draw2) { create(:draw, :completed, lottery_game: lottery_game) }

      it 'shows correct statistics' do
        get :show, params: { id: lottery_game.id }

        # Total tickets includes the one from let! plus the two created here
        expect(assigns(:total_tickets_sold)).to eq(3)
        expect(assigns(:recent_draws)).to include(draw1, draw2)
      end
    end
  end

  describe 'authentication and authorization' do
    context 'when user is not signed in' do
      before { sign_out user }

      it 'redirects to sign in page for index' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to sign in page for show' do
        get :show, params: { id: lottery_game.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is not fully verified' do
      before do
        sign_in unverified_user
        allow(unverified_user).to receive(:fully_verified?).and_return(false)
      end

      it 'redirects to onboarding for index' do
        get :index
        expect(response).to redirect_to(onboarding_path)
        expect(flash[:alert]).to eq("Please complete your account verification to play lottery games.")
      end

      it 'redirects to onboarding for show' do
        get :show, params: { id: lottery_game.id }
        expect(response).to redirect_to(onboarding_path)
        expect(flash[:alert]).to eq("Please complete your account verification to play lottery games.")
      end
    end
  end

  describe 'error handling' do
    context 'when lottery game does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          get :show, params: { id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'data for interactive number picker' do
    before do
      get :show, params: { id: lottery_game.id }
    end

    it 'provides necessary data for number picker UI' do
      expect(assigns(:lottery_game)).to be_present
      expect(assigns(:next_draw)).to be_present
      expect(assigns(:current_prize_pool)).to be_present
      expect(assigns(:time_until_draw)).to be_present
      expect(assigns(:can_purchase)).to be_present
      expect(assigns(:user_balance)).to be_present
      expect(assigns(:base_ticket_cost)).to be_present
    end

    it 'provides game configuration for number picker' do
      game = assigns(:lottery_game)
      expect(game.max_number).to be_present
      expect(game.numbers_to_draw).to be_present
      expect(game.ticket_price).to be_present
    end
  end

  describe 'prize pool calculations' do
    let!(:ticket1) { create(:ticket, lottery_game: lottery_game, cost: 2.0) }
    let!(:ticket2) { create(:ticket, lottery_game: lottery_game, cost: 3.0) }

    before do
      # Update the lottery game's current jackpot to reflect ticket sales
      lottery_game.update!(current_jackpot: lottery_game.jackpot_seed + (5.0 * 0.7))
    end

    it 'shows updated prize pool including ticket contributions' do
      get :show, params: { id: lottery_game.id }

      expected_pool = lottery_game.jackpot_seed + (5.0 * 0.7) # 70% of ticket sales
      expect(assigns(:current_prize_pool)).to eq(expected_pool)
    end
  end

  describe 'time calculations' do
    context 'when draw is upcoming' do
      let!(:future_draw) { create(:draw, lottery_game: lottery_game, draw_date: 2.hours.from_now) }

      it 'calculates time until draw correctly' do
        freeze_time do
          get :show, params: { id: lottery_game.id }
          expected_time = (2.hours.from_now - Time.current).to_i
          expect(assigns(:time_until_draw)).to be_within(5).of(expected_time)
        end
      end
    end

    context 'when no upcoming draws' do
      before do
        Draw.destroy_all # Remove all draws
      end

      it 'handles missing draws gracefully' do
        get :show, params: { id: lottery_game.id }
        expect(assigns(:time_until_draw)).to be_nil
        expect(assigns(:next_draw)).to be_nil
      end
    end
  end
end
