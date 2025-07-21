class PayoutProcessingService
  # This service handles payout processing for winning bets

  def initialize(bet)
    @bet = bet
    @lottery = bet.lottery
    @user = bet.user
  end

  # Process payout for a winning bet
  def process_payout
    # Only process payouts for confirmed winning bets
    return { success: false, error: "Bet is not eligible for payout" } unless @bet.won? && @bet.confirmed_on_chain?

    # Check if payout was already processed
    return { success: false, error: "Payout already processed" } if payout_already_processed?

    # Calculate payout amount based on lottery payout strategy
    payout_amount = calculate_payout_amount

    # In MVP, we'll simulate blockchain transaction for payout
    # In Phase 2, this would create an actual blockchain transaction
    transaction_hash = generate_mock_transaction_hash

    # Create payout record
    payout = create_payout_record(payout_amount, transaction_hash)

    # Update bet status
    @bet.update(paid_out: true, payout_transaction_hash: transaction_hash)

    # Return success response
    {
      success: true,
      payout_id: payout.id,
      amount: payout_amount,
      transaction_hash: transaction_hash,
      processed_at: payout.created_at
    }
  rescue => e
    # Handle payout errors
    {
      success: false,
      error: e.message
    }
  end

  # Calculate potential payout for a bet (before it's confirmed)
  def calculate_potential_payout
    odds = @lottery.odds_json["win_probability"].to_f

    case @lottery.payout_strategy
    when "fixed_multiplier"
      multiplier = @lottery.payout_strategy_json["multiplier"].to_f
      @bet.amount * multiplier
    when "odds_based"
      # Payout based on true odds (1/probability)
      # With a small house edge
      house_edge = @lottery.payout_strategy_json["house_edge"].to_f || 0.05
      true_odds = (1.0 / odds) * (1.0 - house_edge)
      @bet.amount * true_odds
    when "progressive"
      # Base payout plus progressive jackpot contribution
      base_multiplier = @lottery.payout_strategy_json["base_multiplier"].to_f
      jackpot_contribution = @lottery.payout_strategy_json["jackpot_contribution"].to_f || 0
      @bet.amount * base_multiplier + jackpot_contribution
    else
      # Default to 2x for unknown strategies
      @bet.amount * 2
    end
  end

  private

  # Check if payout was already processed
  def payout_already_processed?
    @bet.paid_out? || PayoutLog.exists?(bet_id: @bet.id)
  end

  # Calculate payout amount based on lottery payout strategy
  def calculate_payout_amount
    # Use the same logic as calculate_potential_payout
    # But this is the actual payout calculation
    calculate_potential_payout
  end

  # Create payout record in database
  def create_payout_record(amount, transaction_hash)
    PayoutLog.create!(
      user_id: @user.id,
      bet_id: @bet.id,
      lottery_id: @lottery.id,
      amount: amount,
      transaction_hash: transaction_hash,
      status: "completed"
    )
  end

  # Generate mock transaction hash for MVP
  def generate_mock_transaction_hash
    "0x#{SecureRandom.hex(32)}"
  end
end
