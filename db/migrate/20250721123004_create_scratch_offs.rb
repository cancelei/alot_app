class CreateScratchOffs < ActiveRecord::Migration[8.0]
  def change
    create_table :scratch_offs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :instant_game, null: false, foreign_key: true
      t.datetime :purchase_date, null: false
      t.decimal :cost, precision: 10, scale: 2, null: false
      t.integer :status, null: false, default: 0

      # Scratch results
      t.decimal :prize_won, precision: 15, scale: 2, default: 0.0
      t.datetime :scratched_at
      t.datetime :claimed_at

      # Digital ticket data
      t.string :ticket_serial_number
      t.json :scratch_areas_data

      # Second chance
      t.boolean :second_chance_entered, null: false, default: false
      t.datetime :second_chance_entered_at

      t.timestamps
    end

    add_index :scratch_offs, [ :user_id, :status ]
    add_index :scratch_offs, [ :instant_game_id, :status ]
    add_index :scratch_offs, :purchase_date
    add_index :scratch_offs, [ :status, :prize_won ]
    add_index :scratch_offs, :ticket_serial_number, unique: true
  end
end
