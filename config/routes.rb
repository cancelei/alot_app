Rails.application.routes.draw do
  # Onboarding routes
  get "onboarding", to: "onboarding#index"
  get "onboarding/age_verification", to: "onboarding#age_verification"
  post "onboarding/age_verification", to: "onboarding#age_verification"
  get "onboarding/location_verification", to: "onboarding#location_verification"
  post "onboarding/location_verification", to: "onboarding#location_verification"
  get "onboarding/identity_verification", to: "onboarding#identity_verification"
  post "onboarding/identity_verification", to: "onboarding#identity_verification"
  get "onboarding/tutorial", to: "onboarding#tutorial"
  post "onboarding/tutorial", to: "onboarding#tutorial"
  get "onboarding/complete", to: "onboarding#complete"
  resources :bets, only: [] do
    resources :drawn_numbers, only: [ :create ]
  end
  # Dashboard routes
  get "dashboard", to: "dashboard#index"
  get "dashboard/index", to: "dashboard#index"

  # Devise routes for authentication with custom controllers
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  # Root path
  root "home#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # American Lottery System Routes

  # Lottery Games (Admin-configurable games)
  resources :lottery_games, only: [ :index, :show ] do
    resources :tickets, except: [ :edit, :update, :destroy ] do
      member do
        post :claim_prize
      end
      collection do
        post :quick_pick
        get :prize_pool_update
      end
    end
  end

  # Instant Games (Scratch-offs)
  resources :instant_games, only: [ :index, :show ] do
    resources :scratch_offs, only: [ :create, :show ] do
      member do
        post :scratch
        post :claim_prize
        post :enter_second_chance
      end
    end
  end

  # Tickets management
  resources :tickets, only: [ :index, :show ] do
    member do
      post :claim_prize
    end
  end

  # Scratch-offs management
  resources :scratch_offs, only: [ :index, :show ] do
    member do
      post :scratch
      post :claim_prize
      post :enter_second_chance
    end
  end

  # Legacy Player routes (maintain backward compatibility)
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

  # User Prize Claims
  resources :prize_claims, only: [ :index, :show ] do
    member do
      post :claim
    end
  end

  # Admin routes
  namespace :admin do
    get "reports/players"
    get "reports/bets"
    get "reports/payouts"
    get "dashboard/index"
    # Admin dashboard
    get "/", to: "dashboard#index", as: :dashboard

    # American Lottery System Admin Routes

    # Lottery Games Management
    resources :lottery_games do
      member do
        post :activate
        post :pause
        post :schedule_draw
        # Cycle management routes
        get :configure_cycles
        post :start_cycles
        post :complete_cycles
      end
      collection do
        post :create_rapid_game
        post :create_hourly_game
        post :create_daily_game
        post :create_weekly_game
      end
    end

    # Instant Games Management
    resources :instant_games do
      member do
        post :activate
        post :pause
        post :add_tickets
      end
      collection do
        post :create_dollar_game
        post :create_five_dollar_game
        post :create_ten_dollar_game
        get :prize_structure_builder
      end
    end

    # User Management
    resources :users, only: [ :index, :show, :edit, :update ] do
      member do
        post :activate
        post :deactivate
        post :verify_identity
        post :reject_identity
        patch :update_role
        patch :update_limits
      end
    end

    # State Jurisdictions Management
    resources :state_jurisdictions, only: [ :index, :show, :edit, :update ]

    # Identity Verifications Management
    resources :identity_verifications, only: [ :index, :show, :update ] do
      member do
        post :approve
        post :reject
      end
    end

    # Draw Management
    resources :draws, only: [ :index, :show ] do
      member do
        post :execute_draw
        post :cancel_draw
      end
    end

    # Prize Claims Management
    resources :prize_claims, only: [ :index, :show, :edit, :update ] do
      member do
        patch :process_claim
        patch :expire_claim
      end
      collection do
        post :bulk_process
      end
    end

    # Admin payout management
    resources :payouts, only: [ :index, :show ] do
      collection do
        get :pending
        post :process_all_pending
      end
    end

    # Process individual payout
    post "bets/:id/process_payout", to: "payouts#process_payout", as: :process_payout

    # Legacy Admin lottery management
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

    # Enhanced Admin reports
    namespace :reports do
      get :players
      get :bets
      get :payouts
      get :lottery_games
      get :instant_games
      get :revenue
      get :compliance
    end
  end
end
