class CreateLotteries < ActiveRecord::Migration[8.0]
  def change
    create_table :lotteries do |t|
      t.string :name
      t.text :description
      t.integer :status
      t.jsonb :odds_json
      t.integer :cycles_count
      t.decimal :reinvestment_ratio
      t.boolean :is_endless
      t.string :smart_contract_address
      t.integer :payout_strategy
      t.integer :visibility
      t.datetime :deployed_at
      t.decimal :current_payout, precision: 15, scale: 2, default: 0
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
