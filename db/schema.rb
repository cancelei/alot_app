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

ActiveRecord::Schema[8.0].define(version: 2025_06_12_142340) do
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
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "bets", "lotteries"
  add_foreign_key "bets", "users", column: "player_id"
  add_foreign_key "drawn_numbers", "bets"
  add_foreign_key "drawn_numbers", "lotteries"
  add_foreign_key "drawn_numbers", "users"
  add_foreign_key "feature_requests", "users", column: "submitted_by_id"
  add_foreign_key "lotteries", "users", column: "created_by_id"
  add_foreign_key "payout_logs", "bets"
  add_foreign_key "payout_logs", "lotteries"
  add_foreign_key "payout_logs", "users", column: "player_id"
end
