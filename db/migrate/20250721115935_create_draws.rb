class CreateDraws < ActiveRecord::Migration[8.0]
  def change
    create_table :draws do |t|
      t.references :lottery, null: false, foreign_key: true
      t.datetime :draw_date, null: false
      t.text :winning_numbers
      t.decimal :jackpot_amount, precision: 15, scale: 2, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :draws, [ :lottery_id, :draw_date ]
    add_index :draws, [ :lottery_id, :status ]
    add_index :draws, :draw_date
  end
end
