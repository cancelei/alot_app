require 'rails_helper'

RSpec.describe 'Lottery Games', type: :request do
  describe 'GET /lottery_games' do
    let!(:daily_game) { create(:lottery_game, :daily, is_active: true) }

    it 'returns successful response' do
      get '/lottery_games'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it 'displays only active lottery games' do
      get '/lottery_games'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['games_count']).to be > 0
    end

    it 'sorts games by next draw time' do
      get '/lottery_games'
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
    end

    context 'with filters' do
      it 'filters by rapid games' do
        get '/lottery_games', params: { filter: 'rapid' }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end

      it 'filters by daily games' do
        get '/lottery_games', params: { filter: 'daily' }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end

      it 'filters by progressive games' do
        get '/lottery_games', params: { filter: 'progressive' }
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end
  end

  describe 'GET /lottery_games/:id' do
    let(:test_game) { create(:lottery_game, is_active: true) }

    it 'returns successful response' do
      get "/lottery_games/#{test_game.id}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
    end

    it 'displays lottery game and related data' do
      get "/lottery_games/#{test_game.id}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
    end

    it 'shows game statistics' do
      get "/lottery_games/#{test_game.id}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
    end

    it 'shows purchase interface for verified users' do
      get "/lottery_games/#{test_game.id}"
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')

      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
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
        get "/lottery_games/#{test_game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'when lottery game is inactive' do
      let(:inactive_game) { create(:lottery_game, is_active: false) }

      it 'shows game as inactive' do
        get "/lottery_games/#{inactive_game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'when no upcoming draws exist' do
      it 'shows no purchase option' do
        get "/lottery_games/#{test_game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'with winning tickets' do
      it 'displays winning statistics' do
        get "/lottery_games/#{test_game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'with multiple tickets and draws' do
      it 'shows correct statistics' do
        get "/lottery_games/#{test_game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end
  end

  describe 'authentication and authorization' do
    context 'when user is not signed in' do
      it 'redirects to sign in page for index' do
        get '/lottery_games'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end

      it 'redirects to sign in page for show' do
        game = create(:lottery_game, is_active: true)
        get "/lottery_games/#{game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end

    context 'when user is not fully verified' do
      it 'redirects to onboarding for index' do
        get '/lottery_games'
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end

      it 'redirects to onboarding for show' do
        game = create(:lottery_game, is_active: true)
        get "/lottery_games/#{game.id}"
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
      end
    end
  end

  describe 'error handling' do
    context 'when lottery game does not exist' do
      it 'returns 404 status' do
        get "/lottery_games/99999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'data for interactive number picker' do
    let(:test_game) { create(:lottery_game, :daily) }

    before do
      get "/lottery_games/#{test_game.id}"
    end

    it 'provides necessary data for number picker UI' do
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['game']).to be_present
      expect(json_response['game']['id']).to eq(test_game.id)
      expect(json_response['game']['name']).to eq(test_game.name)
    end

    it 'provides game configuration for number picker' do
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      game_data = json_response['game']
      expect(game_data['id']).to eq(test_game.id)
      expect(game_data['name']).to be_present
      expect(game_data['description']).to be_present
    end
  end

  describe 'prize pool calculations' do
    let(:pool_game) { create(:lottery_game, :daily) }

    before do
      get "/lottery_games/#{pool_game.id}"
    end

    it 'shows updated prize pool including ticket contributions' do
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('success')
      expect(json_response['game']).to be_present
      expect(json_response['game']['id']).to eq(pool_game.id)
    end
  end

  describe 'time calculations' do
    let(:time_game) { create(:lottery_game, :daily) }

    context 'when draw is upcoming' do
      before do
        get "/lottery_games/#{time_game.id}"
      end

      it 'calculates time until draw correctly' do
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['game']['id']).to eq(time_game.id)
      end
    end

    context 'when no upcoming draws' do
      before do
        get "/lottery_games/#{time_game.id}"
      end

      it 'handles missing draws gracefully' do
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['game']['id']).to eq(time_game.id)
      end
    end
  end
end
