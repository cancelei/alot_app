class AddCategoryToFeatureRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :feature_requests, :category, :string
  end
end
