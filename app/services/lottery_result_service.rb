class LotteryResultService
  # This service handles the transparent calculation of lottery results
  # In MVP, we'll use Ruby's random number generator with a seed based on transaction hash
  # In Phase 2, this would be replaced with on-chain randomness from Polkadot

  def initialize(bet)
    @bet = bet
    @lottery = bet.lottery
  end

  def calculate_result
    # Get the win probability from the lottery's odds_json
    win_probability = @lottery.odds_json["win_probability"].to_f

    # Generate a deterministic random number based on the transaction hash
    # This ensures transparency and verifiability
    random_value = generate_deterministic_random

    # Determine if bet is won or lost based on win probability
    if random_value < win_probability
      :won
    else
      :lost
    end
  end

  private

  def generate_deterministic_random
    # In MVP, we'll use a deterministic random number generator
    # based on the transaction hash to ensure transparency
    # In Phase 2, this would use on-chain randomness from Polkadot

    # Create a deterministic seed from the transaction hash
    seed = create_seed_from_transaction

    # Use the seed to generate a random number between 0 and 1
    Random.new(seed).rand
  end

  def create_seed_from_transaction
    # Extract a numeric seed from the transaction hash
    # This ensures that the result is verifiable and transparent

    # Remove '0x' prefix if present
    hash = @bet.signed_transaction_payload.sub(/^0x/, "")

    # Take the first 8 characters of the hash and convert to integer
    hash[0..7].to_i(16)
  end
end
