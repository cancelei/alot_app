class CreateInstantGames < ActiveRecord::Migration[8.0]
  def change
    create_table :instant_games do |t|
      t.references :state_jurisdiction, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description
      t.integer :status, null: false, default: 0

      # Game configuration
      t.decimal :price_point, precision: 10, scale: 2, null: false
      t.integer :total_tickets, null: false
      t.integer :tickets_remaining
      t.decimal :top_prize_amount, precision: 15, scale: 2, null: false
      t.decimal :overall_odds, precision: 10, scale: 2, null: false

      # Prize structure (JSON)
      t.json :prize_structure

      # Game design
      t.string :theme
      t.text :game_instructions
      t.string :ticket_design_url

      # Second chance promotion
      t.text :second_chance_promotion
      t.boolean :second_chance_eligible, null: false, default: false

      # Launch and end dates
      t.datetime :launch_date
      t.datetime :end_date

      t.timestamps
    end

    add_index :instant_games, [ :state_jurisdiction_id, :status ]
    add_index :instant_games, :price_point
    add_index :instant_games, :status
    add_index :instant_games, :created_by_id
    add_index :instant_games, [ :status, :tickets_remaining ]
  end
end
