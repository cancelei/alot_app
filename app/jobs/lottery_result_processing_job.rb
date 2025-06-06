class LotteryResultProcessingJob < ApplicationJob
  queue_as :default

  # Process lottery results for a specific lottery cycle
  # This job handles the calculation of lottery results and updates bet statuses
  def perform(lottery_id, cycle_number)
    lottery = Lottery.find_by(id: lottery_id)
    return unless lottery

    # Log the start of processing
    Rails.logger.info("Processing lottery results for #{lottery.name} (ID: #{lottery_id}) - Cycle ##{cycle_number}")

    # Get all bets for this lottery cycle
    bets = Bet.where(lottery_id: lottery_id, cycle_number: cycle_number, confirmed_on_chain: true)

    if bets.empty?
      Rails.logger.info("No confirmed bets found for lottery #{lottery_id}, cycle #{cycle_number}")
      return
    end

    # Get or generate the winning number for this lottery cycle
    winning_number = get_winning_number(lottery, cycle_number)

    # Process each bet against the winning number
    process_bets(bets, winning_number, lottery)

    # Update lottery statistics
    update_lottery_statistics(lottery)

    # Log completion
    Rails.logger.info("Completed processing lottery results for #{lottery.name} (ID: #{lottery_id}) - Cycle ##{cycle_number}")
  end

  private

  # Get or generate the winning number for this lottery cycle
  def get_winning_number(lottery, cycle_number)
    # Check if we already have a winning number stored
    result = LotteryResult.find_by(lottery_id: lottery.id, cycle_number: cycle_number)

    if result&.winning_number.present?
      return result.winning_number
    end

    # Generate a new winning number using the lottery's randomness source
    winning_number = generate_winning_number(lottery)

    # Store the winning number
    LotteryResult.create!(
      lottery_id: lottery.id,
      cycle_number: cycle_number,
      winning_number: winning_number,
      result_hash: generate_result_hash(lottery, cycle_number, winning_number),
      verified_at: Time.current
    )

    winning_number
  end

  # Generate a winning number based on the lottery's configuration
  def generate_winning_number(lottery)
    # In MVP, we'll use a simulated random number
    # In Phase 2, this would use a verifiable random function from the blockchain
    case lottery.randomness_source
    when "blockchain_hash"
      # Simulate a blockchain hash-based random number
      SecureRandom.hex(32)
    when "vrf"
      # Simulate a VRF (Verifiable Random Function) result
      SecureRandom.hex(16)
    else
      # Default to simple random number in the lottery's range
      min = lottery.min_value || 1
      max = lottery.max_value || 100
      rand(min..max).to_s
    end
  end

  # Generate a hash of the lottery result for verification
  def generate_result_hash(lottery, cycle_number, winning_number)
    # In MVP, we'll use a simple hash
    # In Phase 2, this would be a cryptographic proof from the blockchain
    data = {
      lottery_id: lottery.id,
      cycle_number: cycle_number,
      winning_number: winning_number,
      timestamp: Time.current.to_i
    }

    Digest::SHA256.hexdigest(data.to_json)
  end

  # Process all bets against the winning number
  def process_bets(bets, winning_number, lottery)
    bets.each do |bet|
      # Determine if the bet is a winner
      is_winner = determine_winner(bet, winning_number, lottery)

      # Update bet status
      if is_winner
        bet.update(result: :won)
        Rails.logger.info("Bet ##{bet.id} is a winner!")
      else
        bet.update(result: :lost)
        Rails.logger.info("Bet ##{bet.id} is a loser.")
      end
    end
  end

  # Determine if a bet is a winner based on the lottery rules and winning number
  def determine_winner(bet, winning_number, lottery)
    # This logic will vary based on the lottery type
    case lottery.lottery_type
    when "number_match"
      # Direct number match
      bet.chosen_numbers == winning_number
    when "number_range"
      # Number within a range
      bet_number = bet.chosen_numbers.to_i
      win_number = winning_number.to_i

      min_range = bet_number - lottery.range_buffer
      max_range = bet_number + lottery.range_buffer

      win_number >= min_range && win_number <= max_range
    when "random_chance"
      # Random chance based on odds
      # In MVP, we'll simulate this with a random number
      odds = lottery.odds_json["win_probability"].to_f
      rand < odds
    else
      # Default lottery logic - simple random chance
      rand < 0.5 # 50% chance
    end
  end

  # Update lottery statistics after processing results
  def update_lottery_statistics(lottery)
    # Count total bets, wins, and losses
    total_bets = lottery.bets.confirmed_bets.count
    won_bets = lottery.bets.won_bets.count
    lost_bets = lottery.bets.lost_bets.count

    # Calculate win rate
    win_rate = total_bets > 0 ? (won_bets.to_f / total_bets) * 100 : 0

    # Update lottery statistics
    lottery.update(
      total_bets_count: total_bets,
      won_bets_count: won_bets,
      lost_bets_count: lost_bets,
      win_rate: win_rate
    )
  end
end
