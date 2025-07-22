class AddStateJurisdictionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :state_jurisdiction, null: true, foreign_key: true
    add_column :users, :ssn_last_four, :string, limit: 4
    add_column :users, :address_line_1, :string
    add_column :users, :address_line_2, :string
    add_column :users, :city, :string
    add_column :users, :state, :string, limit: 2
    add_column :users, :zip_code, :string
    add_column :users, :responsible_gaming_limits_set, :boolean, default: false, null: false
    add_column :users, :self_exclusion_until, :datetime
    add_column :users, :last_activity_at, :datetime

    add_index :users, :state_jurisdiction_id
    add_index :users, :ssn_last_four
    add_index :users, :self_exclusion_until
  end
end
