class CycleManagementJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active lottery games with cycles that need processing
    LotteryGame.where(cycle_status: "active").find_each do |lottery_game|
      process_lottery_game_cycles(lottery_game)
    end
  end

  private

  def process_lottery_game_cycles(lottery_game)
    # Check if cycles are completed
    if lottery_game.cycles_completed?
      Rails.logger.info "Processing completed cycles for lottery game: #{lottery_game.name}"

      begin
        lottery_game.complete_cycles!

        # Notify admins if manual review is needed
        if lottery_game.cycle_status == "pending_admin_review"
          AdminNotificationMailer.cycle_requires_review(lottery_game).deliver_now
        end

        Rails.logger.info "Successfully completed cycles for lottery game: #{lottery_game.name}"
      rescue => e
        Rails.logger.error "Failed to complete cycles for lottery game #{lottery_game.name}: #{e.message}"

        # Notify admins of the error
        AdminNotificationMailer.cycle_completion_error(lottery_game, e.message).deliver_now
      end
    end

    # Log cycle progress for monitoring
    Rails.logger.debug "Lottery game #{lottery_game.name}: Cycle #{lottery_game.current_cycle_number}/#{lottery_game.total_cycles} (#{lottery_game.cycle_progress_percentage}% complete)"
  end
end
