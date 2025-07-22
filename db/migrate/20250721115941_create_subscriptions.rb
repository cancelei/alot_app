class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lottery, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.integer :frequency, null: false
      t.datetime :next_purchase_date, null: false
      t.boolean :auto_renew, default: true, null: false

      t.timestamps
    end

    add_index :subscriptions, [ :user_id, :status ]
    add_index :subscriptions, [ :lottery_id, :status ]
    add_index :subscriptions, :next_purchase_date
  end
end
