class PrizePoolUpdateJob < ApplicationJob
  queue_as :default

  def perform(lottery_game_id, contribution_amount = nil)
    lottery_game = LotteryGame.find(lottery_game_id)

    # Calculate current prize pool
    new_pool = lottery_game.current_prize_pool

    # Add any specific contribution if provided
    new_pool += contribution_amount if contribution_amount

    # Update cached prize pool value
    Rails.cache.write(
      "lottery_game_#{lottery_game.id}_current_prize_pool",
      new_pool,
      expires_in: 1.hour
    )

    # Broadcast real-time updates to all connected users
    ActionCable.server.broadcast(
      "lottery_game_#{lottery_game.id}",
      {
        type: "prize_pool_update",
        prize_pool: new_pool,
        updated_at: Time.current,
        tickets_sold: lottery_game.total_tickets_sold
      }
    )

    # Broadcast to general lottery channel for dashboard updates
    ActionCable.server.broadcast(
      "lottery_updates",
      {
        type: "game_update",
        game_id: lottery_game.id,
        game_name: lottery_game.name,
        prize_pool: new_pool,
        updated_at: Time.current
      }
    )

    Rails.logger.info "Updated prize pool for #{lottery_game.name}: $#{new_pool}"
  end
end
