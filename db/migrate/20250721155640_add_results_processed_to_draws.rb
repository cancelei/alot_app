class AddResultsProcessedToDraws < ActiveRecord::Migration[8.0]
  def change
    add_column :draws, :results_processed, :boolean
    add_column :draws, :results_processed_at, :datetime
  end
end
