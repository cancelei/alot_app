class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lottery, null: false, foreign_key: true
      t.references :draw, null: true
      t.text :numbers
      t.datetime :purchase_date
      t.integer :status
      t.decimal :cost, precision: 15, scale: 2
      t.decimal :prize_amount, precision: 15, scale: 2
      t.references :subscription, null: true

      t.timestamps
    end

    add_index :tickets, [ :user_id, :status ]
    add_index :tickets, [ :lottery_id, :status ]
    add_index :tickets, :purchase_date
  end
end
