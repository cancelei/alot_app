class CreateFeatureRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_requests do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.references :submitted_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
