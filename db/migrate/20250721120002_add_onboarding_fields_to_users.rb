class AddOnboardingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :date_of_birth, :date
    add_column :users, :location_verified, :boolean, default: false, null: false
    add_column :users, :identity_verified, :boolean, default: false, null: false
    add_column :users, :phone_number, :string
    add_column :users, :account_balance, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :users, :spending_limit_daily, :decimal, precision: 15, scale: 2
    add_column :users, :spending_limit_weekly, :decimal, precision: 15, scale: 2
    add_column :users, :spending_limit_monthly, :decimal, precision: 15, scale: 2

    add_index :users, :phone_number, unique: true
    add_index :users, [ :location_verified, :identity_verified ]
  end
end
