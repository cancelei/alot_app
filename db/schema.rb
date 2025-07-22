# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_21_184605) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bets", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "lottery_id", null: false
    t.decimal "amount"
    t.text "signed_transaction_payload"
    t.boolean "confirmed_on_chain"
    t.integer "cycle_number"
    t.integer "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_id"], name: "index_bets_on_lottery_id"
    t.index ["player_id"], name: "index_bets_on_player_id"
  end

  create_table "drawn_numbers", force: :cascade do |t|
    t.bigint "lottery_id", null: false
    t.bigint "bet_id", null: false
    t.bigint "user_id", null: false
    t.integer "number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bet_id", "number"], name: "index_drawn_numbers_on_bet_id_and_number", unique: true
    t.index ["bet_id"], name: "index_drawn_numbers_on_bet_id"
    t.index ["lottery_id", "number"], name: "index_drawn_numbers_on_lottery_id_and_number"
    t.index ["lottery_id"], name: "index_drawn_numbers_on_lottery_id"
    t.index ["user_id"], name: "index_drawn_numbers_on_user_id"
  end

  create_table "draws", force: :cascade do |t|
    t.bigint "lottery_game_id", null: false
    t.datetime "draw_date", null: false
    t.text "winning_numbers"
    t.decimal "jackpot_amount", precision: 15, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "results_processed"
    t.datetime "results_processed_at"
    t.index ["draw_date"], name: "index_draws_on_draw_date"
    t.index ["lottery_game_id", "draw_date"], name: "index_draws_on_lottery_game_id_and_draw_date"
    t.index ["lottery_game_id", "status"], name: "index_draws_on_lottery_game_id_and_status"
    t.index ["lottery_game_id"], name: "index_draws_on_lottery_game_id"
  end

  create_table "feature_requests", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "status"
    t.bigint "submitted_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.index ["submitted_by_id"], name: "index_feature_requests_on_submitted_by_id"
  end

  create_table "identity_verifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "verification_type", null: false
    t.integer "status", default: 0, null: false
    t.string "ssn_last_four", limit: 4
    t.string "document_type"
    t.string "document_number"
    t.date "document_expiry_date"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.datetime "verification_date", precision: nil
    t.string "verified_by"
    t.text "notes"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["status"], name: "index_identity_verifications_on_status"
    t.index ["user_id"], name: "index_identity_verifications_on_user_id"
    t.index ["verification_type"], name: "index_identity_verifications_on_verification_type"
  end

  create_table "instant_games", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "ticket_price", precision: 15, scale: 2, null: false
    t.integer "total_tickets", null: false
    t.integer "remaining_tickets", null: false
    t.decimal "top_prize", precision: 15, scale: 2, null: false
    t.string "overall_odds"
    t.text "prize_structure"
    t.string "game_number"
    t.date "launch_date"
    t.date "end_date"
    t.boolean "second_chance_available", default: false
    t.text "second_chance_description"
    t.boolean "is_active", default: true
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["game_number"], name: "index_instant_games_on_game_number"
    t.index ["is_active"], name: "index_instant_games_on_is_active"
    t.index ["launch_date"], name: "index_instant_games_on_launch_date"
    t.index ["ticket_price"], name: "index_instant_games_on_ticket_price"
  end

  create_table "lotteries", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "status"
    t.jsonb "odds_json"
    t.integer "cycles_count"
    t.decimal "reinvestment_ratio"
    t.boolean "is_endless"
    t.string "smart_contract_address"
    t.integer "payout_strategy"
    t.integer "visibility"
    t.datetime "deployed_at"
    t.decimal "current_payout", precision: 15, scale: 2, default: "0.0"
    t.bigint "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_numbers_to_draw", default: 5
    t.decimal "cost_per_number", precision: 15, scale: 2, default: "1.0"
    t.jsonb "verification_data"
    t.index ["created_by_id"], name: "index_lotteries_on_created_by_id"
  end

  create_table "lottery_games", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "game_type", null: false
    t.integer "draw_frequency", null: false
    t.decimal "ticket_price", precision: 15, scale: 2, null: false
    t.integer "numbers_to_pick", null: false
    t.integer "number_range_min", null: false
    t.integer "number_range_max", null: false
    t.boolean "bonus_ball", default: false
    t.integer "bonus_range_min"
    t.integer "bonus_range_max"
    t.boolean "multiplier_available", default: false
    t.decimal "multiplier_cost", precision: 15, scale: 2
    t.decimal "prize_pool_percentage", precision: 5, scale: 2, null: false
    t.decimal "jackpot_seed", precision: 15, scale: 2, null: false
    t.decimal "jackpot_increment", precision: 5, scale: 4, null: false
    t.decimal "current_jackpot", precision: 15, scale: 2, default: "0.0"
    t.string "winner_selection_mode", null: false
    t.string "pool_reset_rule", null: false
    t.decimal "max_jackpot", precision: 15, scale: 2
    t.datetime "next_draw_at", precision: nil
    t.datetime "last_draw_at", precision: nil
    t.boolean "is_active", default: true
    t.string "created_by"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["draw_frequency"], name: "index_lottery_games_on_draw_frequency"
    t.index ["game_type"], name: "index_lottery_games_on_game_type"
    t.index ["is_active"], name: "index_lottery_games_on_is_active"
    t.index ["next_draw_at"], name: "index_lottery_games_on_next_draw_at"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ticket_id"
    t.bigint "subscription_id"
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.integer "payment_method", null: false
    t.integer "status", default: 0, null: false
    t.string "transaction_id"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["processed_at"], name: "index_payments_on_processed_at"
    t.index ["subscription_id"], name: "index_payments_on_subscription_id"
    t.index ["ticket_id"], name: "index_payments_on_ticket_id"
    t.index ["transaction_id"], name: "index_payments_on_transaction_id", unique: true
    t.index ["user_id", "status"], name: "index_payments_on_user_id_and_status"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "payout_logs", force: :cascade do |t|
    t.bigint "lottery_id", null: false
    t.bigint "player_id", null: false
    t.bigint "bet_id", null: false
    t.decimal "amount"
    t.string "transaction_hash"
    t.integer "cycle_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "reinvested", default: false
    t.index ["bet_id"], name: "index_payout_logs_on_bet_id"
    t.index ["lottery_id"], name: "index_payout_logs_on_lottery_id"
    t.index ["player_id"], name: "index_payout_logs_on_player_id"
  end

  create_table "prize_claims", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ticket_id", null: false
    t.bigint "draw_id", null: false
    t.bigint "lottery_game_id", null: false
    t.decimal "prize_amount", precision: 15, scale: 2, null: false
    t.decimal "tax_withholding_amount", precision: 15, scale: 2
    t.string "status", default: "pending", null: false
    t.datetime "claim_deadline", null: false
    t.datetime "claimed_at"
    t.datetime "expired_at"
    t.bigint "processed_by_id"
    t.text "processing_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id"], name: "index_prize_claims_on_draw_id"
    t.index ["lottery_game_id"], name: "index_prize_claims_on_lottery_game_id"
    t.index ["processed_by_id"], name: "index_prize_claims_on_processed_by_id"
    t.index ["ticket_id"], name: "index_prize_claims_on_ticket_id"
    t.index ["user_id"], name: "index_prize_claims_on_user_id"
  end

  create_table "scratch_offs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "instant_game_id", null: false
    t.string "ticket_number", null: false
    t.datetime "purchase_date", precision: nil
    t.datetime "scratch_date", precision: nil
    t.decimal "prize_amount", precision: 15, scale: 2, default: "0.0"
    t.boolean "is_winner", default: false
    t.boolean "is_scratched", default: false
    t.boolean "is_claimed", default: false
    t.datetime "claim_date", precision: nil
    t.boolean "second_chance_entered", default: false
    t.datetime "second_chance_date", precision: nil
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["instant_game_id"], name: "index_scratch_offs_on_instant_game_id"
    t.index ["is_scratched"], name: "index_scratch_offs_on_is_scratched"
    t.index ["is_winner"], name: "index_scratch_offs_on_is_winner"
    t.index ["purchase_date"], name: "index_scratch_offs_on_purchase_date"
    t.index ["ticket_number"], name: "index_scratch_offs_on_ticket_number", unique: true
    t.index ["user_id"], name: "index_scratch_offs_on_user_id"
  end

  create_table "state_jurisdictions", force: :cascade do |t|
    t.string "state_code", limit: 2, null: false
    t.string "state_name", null: false
    t.integer "minimum_age", default: 18, null: false
    t.decimal "tax_rate", precision: 5, scale: 4, default: "0.0", null: false
    t.boolean "lottery_legal", default: true, null: false
    t.boolean "is_active", default: true, null: false
    t.decimal "winnings_threshold", precision: 15, scale: 2, default: "600.0"
    t.integer "claim_period", default: 180
    t.text "special_rules"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_legal", "is_active"], name: "index_state_jurisdictions_on_lottery_legal_and_is_active"
    t.index ["state_code"], name: "index_state_jurisdictions_on_state_code", unique: true
    t.index ["state_name"], name: "index_state_jurisdictions_on_state_name", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lottery_game_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "frequency", null: false
    t.datetime "next_purchase_date", null: false
    t.boolean "auto_renew", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lottery_game_id", "status"], name: "index_subscriptions_on_lottery_game_id_and_status"
    t.index ["lottery_game_id"], name: "index_subscriptions_on_lottery_game_id"
    t.index ["next_purchase_date"], name: "index_subscriptions_on_next_purchase_date"
    t.index ["user_id", "status"], name: "index_subscriptions_on_user_id_and_status"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lottery_game_id", null: false
    t.bigint "draw_id"
    t.text "numbers"
    t.datetime "purchase_date"
    t.integer "status"
    t.decimal "cost", precision: 15, scale: 2
    t.decimal "prize_amount", precision: 15, scale: 2
    t.bigint "subscription_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draw_id"], name: "index_tickets_on_draw_id"
    t.index ["lottery_game_id", "status"], name: "index_tickets_on_lottery_game_id_and_status"
    t.index ["lottery_game_id"], name: "index_tickets_on_lottery_game_id"
    t.index ["purchase_date"], name: "index_tickets_on_purchase_date"
    t.index ["subscription_id"], name: "index_tickets_on_subscription_id"
    t.index ["user_id", "status"], name: "index_tickets_on_user_id_and_status"
    t.index ["user_id"], name: "index_tickets_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "username"
    t.date "date_of_birth"
    t.boolean "location_verified", default: false, null: false
    t.boolean "identity_verified", default: false, null: false
    t.string "phone_number"
    t.decimal "account_balance", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "spending_limit_daily", precision: 15, scale: 2
    t.decimal "spending_limit_weekly", precision: 15, scale: 2
    t.decimal "spending_limit_monthly", precision: 15, scale: 2
    t.bigint "state_jurisdiction_id"
    t.boolean "self_excluded", default: false
    t.datetime "self_exclusion_date", precision: nil
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["location_verified", "identity_verified"], name: "index_users_on_location_verified_and_identity_verified"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["self_excluded"], name: "index_users_on_self_excluded"
    t.index ["state_jurisdiction_id"], name: "index_users_on_state_jurisdiction_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "bets", "lotteries"
  add_foreign_key "bets", "users", column: "player_id"
  add_foreign_key "drawn_numbers", "bets"
  add_foreign_key "drawn_numbers", "lotteries"
  add_foreign_key "drawn_numbers", "users"
  add_foreign_key "draws", "lottery_games"
  add_foreign_key "feature_requests", "users", column: "submitted_by_id"
  add_foreign_key "identity_verifications", "users", name: "identity_verifications_user_id_fkey"
  add_foreign_key "lotteries", "users", column: "created_by_id"
  add_foreign_key "payments", "subscriptions"
  add_foreign_key "payments", "tickets"
  add_foreign_key "payments", "users"
  add_foreign_key "payout_logs", "bets"
  add_foreign_key "payout_logs", "lotteries"
  add_foreign_key "payout_logs", "users", column: "player_id"
  add_foreign_key "prize_claims", "draws"
  add_foreign_key "prize_claims", "lottery_games"
  add_foreign_key "prize_claims", "tickets"
  add_foreign_key "prize_claims", "users"
  add_foreign_key "prize_claims", "users", column: "processed_by_id"
  add_foreign_key "scratch_offs", "instant_games", name: "scratch_offs_instant_game_id_fkey"
  add_foreign_key "scratch_offs", "users", name: "scratch_offs_user_id_fkey"
  add_foreign_key "subscriptions", "lottery_games"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "tickets", "lottery_games"
  add_foreign_key "tickets", "users"
  add_foreign_key "users", "state_jurisdictions", name: "users_state_jurisdiction_id_fkey"
end
