class CreateLotteryGames < ActiveRecord::Migration[8.0]
  def change
    create_table :lottery_games do |t|
      t.references :state_jurisdiction, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :game_type, null: false, default: 0

      # Game configuration
      t.decimal :ticket_price, precision: 10, scale: 2, null: false
      t.integer :draw_frequency_minutes, null: false
      t.decimal :base_prize_pool, precision: 15, scale: 2, null: false
      t.decimal :contribution_rate, precision: 5, scale: 4, null: false
      t.decimal :platform_fee_rate, precision: 5, scale: 4, null: false

      # Number selection rules
      t.integer :number_range_min, null: false, default: 1
      t.integer :number_range_max, null: false, default: 49
      t.integer :numbers_to_select, null: false, default: 6

      # Winner selection and prize distribution
      t.integer :winner_selection, null: false, default: 0
      t.decimal :first_place_percentage, precision: 5, scale: 4, default: 0.8
      t.decimal :second_place_percentage, precision: 5, scale: 4, default: 0.15
      t.decimal :third_place_percentage, precision: 5, scale: 4, default: 0.05

      # Pool management
      t.integer :pool_reset_rule, null: false, default: 0
      t.decimal :win_reduction_percentage, precision: 5, scale: 4, default: 0.0
      t.decimal :prize_cap, precision: 15, scale: 2
      t.integer :max_players_per_draw

      # Game control
      t.boolean :allows_ticket_sales, null: false, default: true
      t.boolean :allows_quick_pick, null: false, default: true
      t.boolean :allows_multi_draw, null: false, default: true
      t.integer :max_multi_draw_count, default: 26

      # Official game integration
      t.string :official_api_endpoint
      t.string :official_game_id
      t.boolean :requires_official_integration, null: false, default: false

      t.timestamps
    end

    add_index :lottery_games, [ :state_jurisdiction_id, :status ]
    add_index :lottery_games, :game_type
    add_index :lottery_games, :status
    add_index :lottery_games, :created_by_id
  end
end
