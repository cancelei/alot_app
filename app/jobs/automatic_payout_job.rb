class AutomaticPayoutJob < ApplicationJob
  queue_as :default

  # Process automatic payouts for winning bets
  # This job handles the automatic payout of winning bets that have been confirmed on the blockchain
  def perform(lottery_id = nil, cycle_number = nil)
    Rails.logger.info("Starting automatic payout job #{lottery_id ? "for lottery ##{lottery_id}" : "for all lotteries"}")

    # Get all eligible bets for payout
    bets = get_eligible_bets(lottery_id, cycle_number)

    if bets.empty?
      Rails.logger.info("No eligible bets found for payout")
      return
    end

    # Process each bet
    successful_count = 0
    failed_count = 0

    bets.each do |bet|
      begin
        result = process_payout(bet)

        if result[:success]
          successful_count += 1
          Rails.logger.info("Successfully processed payout for bet ##{bet.id}: #{result[:amount]}")
        else
          failed_count += 1
          Rails.logger.error("Failed to process payout for bet ##{bet.id}: #{result[:error]}")
        end
      rescue => e
        failed_count += 1
        Rails.logger.error("Error processing payout for bet ##{bet.id}: #{e.message}")
      end
    end

    # Log completion
    Rails.logger.info("Completed automatic payout job: #{successful_count} successful, #{failed_count} failed")
  end

  private

  # Get all eligible bets for payout
  def get_eligible_bets(lottery_id = nil, cycle_number = nil)
    query = Bet.where(result: :won, confirmed_on_chain: true, paid_out: false)

    # Filter by lottery if specified
    query = query.where(lottery_id: lottery_id) if lottery_id.present?

    # Filter by cycle if specified
    query = query.where(cycle_number: cycle_number) if cycle_number.present?

    # Include necessary associations for efficient processing
    query.includes(:lottery, :user)
  end

  # Process payout for a single bet
  def process_payout(bet)
    # Use the PayoutProcessingService to handle the payout
    payout_service = PayoutProcessingService.new(bet)
    result = payout_service.process_payout

    # If successful, notify the user
    if result[:success]
      # Send notification to user (email, push, etc.)
      notify_user_of_payout(bet, result[:amount], result[:transaction_hash])
    end

    result
  end

  # Notify user of successful payout
  def notify_user_of_payout(bet, amount, transaction_hash)
    # In a real application, this would send an email, push notification, etc.
    # For MVP, we'll just log it
    Rails.logger.info("NOTIFICATION: User #{bet.user.email} received payout of #{amount} for bet ##{bet.id}")

    # In Phase 2, we would implement actual notifications:
    # UserMailer.payout_notification(bet.user, bet, amount, transaction_hash).deliver_later
  end
end
