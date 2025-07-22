class FixSubscriptionsLotteryGameForeignKey < ActiveRecord::Migration[8.0]
  def change
    # Remove the old foreign key constraint to lotteries table
    remove_foreign_key :subscriptions, :lotteries if foreign_key_exists?(:subscriptions, :lotteries)

    # Add the new foreign key constraint to lottery_games table
    add_foreign_key :subscriptions, :lottery_games unless foreign_key_exists?(:subscriptions, :lottery_games)
  end
end
