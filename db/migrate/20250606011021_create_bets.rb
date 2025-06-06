class CreateBets < ActiveRecord::Migration[8.0]
  def change
    create_table :bets do |t|
      t.references :player, null: false, foreign_key: { to_table: :users }
      t.references :lottery, null: false, foreign_key: true
      t.decimal :amount
      t.text :signed_transaction_payload
      t.boolean :confirmed_on_chain
      t.integer :cycle_number
      t.integer :result

      t.timestamps
    end
  end
end
