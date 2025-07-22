class CreateStateJurisdictions < ActiveRecord::Migration[8.0]
  def change
    create_table :state_jurisdictions do |t|
      t.string :state_code, null: false, limit: 2
      t.string :state_name, null: false
      t.integer :minimum_age, null: false, default: 18
      t.decimal :tax_rate, precision: 5, scale: 4, null: false, default: 0.0
      t.boolean :lottery_legal, null: false, default: true
      t.boolean :is_active, null: false, default: true
      t.decimal :winnings_threshold, precision: 15, scale: 2, default: 600.0
      t.integer :claim_period, default: 180 # days
      t.text :special_rules
      t.timestamps
    end

    add_index :state_jurisdictions, :state_code, unique: true
    add_index :state_jurisdictions, :state_name, unique: true
    add_index :state_jurisdictions, [ :lottery_legal, :is_active ]
  end
end
