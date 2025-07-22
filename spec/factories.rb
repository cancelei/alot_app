FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    name { Faker::Name.name }
    password { "password123" }
    password_confirmation { "password123" }
    role { "player" }
    date_of_birth { 25.years.ago }
    location_verified { true }
    identity_verified { true }
    account_balance { 1000.00 }
    spending_limit_daily { 100.00 }
    spending_limit_weekly { 500.00 }
    spending_limit_monthly { 2000.00 }
    self_excluded { false }
    association :state_jurisdiction

    trait :admin do
      role { "super_admin" }
    end

    trait :unverified do
      location_verified { false }
      identity_verified { false }
      date_of_birth { nil }
    end

    trait :self_excluded do
      self_excluded { true }
    end

    trait :insufficient_funds do
      account_balance { 1.0 }
    end
  end

  factory :state_jurisdiction do
    state_code { "CA" }
    state_name { "California" }
    minimum_age { 18 }
    tax_rate { 0.13 }
    is_active { true }
    lottery_legal { true }
    winnings_threshold { 600.0 }
    claim_period { 180 }
  end

  factory :lottery_game do
    sequence(:name) { |n| "Test Lottery #{n}" }
    description { "A test lottery game" }
    game_type { "rapid" }
    ticket_price { 2.0 }
    draw_frequency { 5 } # Default for rapid games
    jackpot_seed { 10000.0 }
    jackpot_increment { 0.1 }
    prize_pool_percentage { 70.0 }
    number_range_min { 1 }
    number_range_max { 50 }
    numbers_to_pick { 6 }
    winner_selection_mode { "random" }
    pool_reset_rule { "reset_to_seed" }
    is_active { true }
    current_jackpot { 0.0 }

    # Trait for daily games with correct draw frequency
    trait :daily do
      game_type { "daily" }
      draw_frequency { 1440 } # 24 hours in minutes for daily games
    end

    # Trait for weekly games
    trait :weekly do
      game_type { "weekly" }
      draw_frequency { 10080 } # 7 days in minutes for weekly games
    end
  end

  factory :draw do
    lottery_game
    draw_date { 1.hour.from_now }
    jackpot_amount { 10000.0 }
    status { 0 } # scheduled

    trait :upcoming do
      draw_date { 1.hour.from_now }
      status { 0 } # scheduled
    end

    trait :completed do
      draw_date { 1.hour.ago }
      status { 2 } # completed
      winning_numbers { [ 1, 2, 3, 4, 5, 6 ] }
    end
  end

  factory :ticket do
    user
    lottery_game
    draw
    numbers { [ 1, 2, 3, 4, 5, 6 ] }
    cost { 2.0 }
    purchase_date { Time.current }
    status { "active" }

    trait :winning do
      status { "won" }
      prize_amount { 100.0 }
    end

    trait :losing do
      status { "lost" }
    end
  end

  factory :payment do
    user
    ticket
    amount { 2.0 }
    payment_type { "ticket_purchase" }
    status { "completed" }
    processed_at { Time.current }

    trait :pending do
      status { "pending" }
      processed_at { nil }
    end

    trait :failed do
      status { "failed" }
    end
  end

  factory :payout_log do
    user
    ticket
    amount { 100.0 }
    payout_type { "prize_claim" }
    status { "pending" }

    trait :completed do
      status { "completed" }
      confirmed_on_chain { true }
    end

    trait :cycle_winner do
      payout_type { "cycle_completion_winner_takes_all" }
      amount { 500.0 }
    end

    trait :cycle_refund do
      payout_type { "cycle_completion_refund" }
      amount { 2.0 }
      status { "completed" }
    end
  end
end
