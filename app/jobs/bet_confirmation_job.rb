class BetConfirmationJob < ApplicationJob
  queue_as :default

  def perform(bet_id)
    # Find the bet
    bet = Bet.find_by(id: bet_id)
    return unless bet

    # Simulate blockchain confirmation using BlockchainTransactionService
    if simulate_blockchain_confirmation(bet)
      # Determine if bet is won or lost based on lottery odds
      determine_bet_result(bet)

      # Create payout log if bet is won
      create_payout_log(bet) if bet.won?
    end
  end

  private

  def determine_bet_result(bet)
    # Use the LotteryResultService for transparent result calculation
    result_service = LotteryResultService.new(bet)
    result = result_service.calculate_result

    # Update bet result
    bet.update(result: result)
  end

  def create_payout_log(bet)
    # Calculate payout amount based on lottery's payout strategy
    payout_amount = calculate_payout_amount(bet)

    # Create payout log
    PayoutLog.create!(
      lottery: bet.lottery,
      player: bet.player,
      bet: bet,
      amount: payout_amount,
      transaction_hash: "0x#{SecureRandom.hex(32)}", # Mock transaction hash
      cycle_number: bet.cycle_number
    )

    # Update lottery's current payout
    update_lottery_payout(bet.lottery, payout_amount)
  end

  def calculate_payout_amount(bet)
    # In a real implementation, this would be based on the lottery's payout strategy
    # For MVP, we'll use a simple multiplier
    case bet.lottery.payout_strategy
    when "fixed_multiplier"
      bet.amount * 2 # Double the bet amount
    when "progressive"
      bet.amount * 1.5 # 1.5x the bet amount
    when "jackpot"
      bet.amount * 10 # 10x the bet amount (big win!)
    else
      bet.amount * 2 # Default to double
    end
  end

  def update_lottery_payout(lottery, payout_amount)
    # Update lottery's current payout
    # In a real implementation, this would be based on the lottery's reinvestment ratio
    reinvestment_amount = payout_amount * lottery.reinvestment_ratio
    lottery.update(current_payout: lottery.current_payout + reinvestment_amount)
  end

  def simulate_blockchain_confirmation(bet)
    # Use BlockchainTransactionService to simulate blockchain confirmation
    blockchain_service = BlockchainTransactionService.new(bet)
    confirmation_result = blockchain_service.simulate_confirmation

    if confirmation_result[:status] == "confirmed"
      # Update bet status to confirmed
      bet.update(confirmed_on_chain: true)
      true
    else
      # Update bet status to failed with error message
      bet.update(
        result: :failed,
        confirmed_on_chain: false,
        failure_reason: confirmation_result[:error_message]
      )
      false
    end
  end
end
