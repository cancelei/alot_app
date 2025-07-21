Rails.application.routes.draw do
  resources :bets, only: [] do
    resources :drawn_numbers, only: [ :create ]
  end
  get "dashboard/index"
  # Devise routes for authentication with custom controllers
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root path
  root "home#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Player routes
  resources :lotteries, only: [ :index, :show ] do
    resources :bets, only: [ :create ]
    member do
      get :verify, to: "verifications#verify_lottery"
    end

    collection do
      get :feature_requests, to: "lotteries#feature_requests"
      get "game_types/:type", to: "lotteries#game_type", as: :game_type
    end
  end

  resources :bets, only: [ :show ] do
    member do
      get :verify, to: "verifications#verify_bet"
      get :verify_result, to: "verifications#verify_result"
    end
  end

  # Verification routes (public for transparency)
  namespace :verification do
    get "lottery/:lottery_id/cycle/:cycle_number", to: "verification#lottery_result", as: :lottery_result
    get "bet/:id", to: "verification#bet", as: :bet
    get "payout/:id", to: "verification#payout", as: :payout
  end

  # Feature request routes for players
  resources :feature_requests, only: [ :new, :create, :index ]

  # Blockchain wallet routes (placeholder for Phase 2)
  resources :blockchain_wallets, only: [ :index ] do
    collection do
      post :connect
      delete :disconnect
    end
  end

  # Dashboard for players
  get "dashboard", to: "dashboard#index", as: :player_dashboard

  # Admin routes
  namespace :admin do
    get "reports/players"
    get "reports/bets"
    get "reports/payouts"
    get "dashboard/index"
    # Admin dashboard
    get "/", to: "dashboard#index", as: :dashboard

    # Admin payout management
    resources :payouts, only: [ :index, :show ] do
      collection do
        get :pending
        post :process_all_pending
      end
    end

    # Process individual payout
    post "bets/:id/process_payout", to: "payouts#process_payout", as: :process_payout

    # Admin lottery management
    resources :lotteries do
      member do
        post :publish
        post :deploy_contract
      end
    end

    # Admin feature request management
    resources :feature_requests, only: [ :index, :show, :update ] do
      member do
        patch :change_status
      end
    end

    # Admin reports
    namespace :reports do
      get :players
      get :bets
      get :payouts
    end
  end
end
