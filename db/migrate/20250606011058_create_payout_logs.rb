class CreatePayoutLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :payout_logs do |t|
      t.references :lottery, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: { to_table: :users }
      t.references :bet, null: false, foreign_key: true
      t.decimal :amount
      t.string :transaction_hash
      t.integer :cycle_number

      t.timestamps
    end
  end
end
