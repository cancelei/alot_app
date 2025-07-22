class FixDrawsForeignKeyConstraint < ActiveRecord::Migration[8.0]
  def change
    # Remove the incorrect foreign key constraint that points to 'lotteries' table
    remove_foreign_key :draws, :lotteries, column: :lottery_game_id

    # Add the correct foreign key constraint that points to 'lottery_games' table
    add_foreign_key :draws, :lottery_games, column: :lottery_game_id
  end
end
