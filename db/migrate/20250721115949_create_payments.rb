class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ticket, null: true, foreign_key: true
      t.references :subscription, null: true, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.integer :payment_method, null: false
      t.integer :status, default: 0, null: false
      t.string :transaction_id
      t.datetime :processed_at

      t.timestamps
    end

    add_index :payments, [ :user_id, :status ]
    add_index :payments, :transaction_id, unique: true
    add_index :payments, :processed_at
  end
end
