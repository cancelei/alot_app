class AddLotteryGameIdToTickets < ActiveRecord::Migration[8.0]
  def change
    # Rename the existing lottery_id column to lottery_game_id
    # This preserves existing data while updating the association
    rename_column :tickets, :lottery_id, :lottery_game_id

    # Update the foreign key constraint if it exists
    # Note: We'll assume lottery_games table exists and has the same IDs as the old lotteries
  end
end
