class FixTicketsLotteryGameForeignKey < ActiveRecord::Migration[8.0]
  def change
    # Remove the old foreign key constraint to lotteries table
    remove_foreign_key :tickets, :lotteries if foreign_key_exists?(:tickets, :lotteries)

    # Add the new foreign key constraint to lottery_games table
    add_foreign_key :tickets, :lottery_games unless foreign_key_exists?(:tickets, :lottery_games)
  end
end
