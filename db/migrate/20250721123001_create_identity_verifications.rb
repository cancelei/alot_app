class CreateIdentityVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :identity_verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ssn_last_four, null: false, limit: 4
      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :city, null: false
      t.string :state, null: false, limit: 2
      t.string :zip_code, null: false
      t.integer :status, null: false, default: 0
      t.integer :verification_method, default: 0
      t.datetime :verified_at
      t.datetime :rejected_at
      t.text :rejection_reason
      t.string :verification_reference_id
      t.timestamps
    end

    add_index :identity_verifications, :user_id, unique: true
    add_index :identity_verifications, :status
    add_index :identity_verifications, :ssn_last_four
  end
end
