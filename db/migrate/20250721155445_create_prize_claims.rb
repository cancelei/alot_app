class CreatePrizeClaims < ActiveRecord::Migration[8.0]
  def change
    create_table :prize_claims do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ticket, null: false, foreign_key: true
      t.references :draw, null: false, foreign_key: true
      t.references :lottery_game, null: false, foreign_key: true
      t.decimal :prize_amount, precision: 15, scale: 2, null: false
      t.decimal :tax_withholding_amount, precision: 15, scale: 2
      t.string :status, null: false, default: 'pending'
      t.datetime :claim_deadline, null: false
      t.datetime :claimed_at
      t.datetime :expired_at
      t.references :processed_by, null: true, foreign_key: { to_table: :users }
      t.text :processing_notes

      t.timestamps
    end
  end
end
