class CreateDrawnNumbers < ActiveRecord::Migration[8.0]
  def change
    create_table :drawn_numbers do |t|
      t.references :lottery, null: false, foreign_key: true
      t.references :bet, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :number, null: false

      t.timestamps
    end

    # Add an index for the combination of bet_id and number to ensure uniqueness
    add_index :drawn_numbers, [ :bet_id, :number ], unique: true

    # Add an index for efficient lookups by lottery and number
    add_index :drawn_numbers, [ :lottery_id, :number ]
  end
end
