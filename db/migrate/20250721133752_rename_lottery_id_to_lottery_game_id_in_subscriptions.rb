class RenameLotteryIdToLotteryGameIdInSubscriptions < ActiveRecord::Migration[8.0]
  def change
    # Rename the existing lottery_id column to lottery_game_id in subscriptions
    rename_column :subscriptions, :lottery_id, :lottery_game_id
  end
end
