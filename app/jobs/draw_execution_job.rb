class DrawExecutionJob < ApplicationJob
  queue_as :default

  def perform(draw_id)
    draw = Draw.find(draw_id)
    lottery_game = draw.lottery_game

    Rails.logger.info "Executing draw #{draw.id} for lottery game #{lottery_game.name}"

    ActiveRecord::Base.transaction do
      # Close entries exactly at deadline
      draw.close_entries!

      # Generate winning numbers using cryptographically secure random generation
      winning_numbers = generate_winning_numbers(lottery_game)
      draw.update!(
        winning_numbers: winning_numbers,
        status: "completed",
        drawn_at: Time.current
      )

      # Determine winners and calculate prizes
      winners = determine_winners(draw)
      total_winners = winners.count

      # Update draw with winner information
      draw.update!(
        total_winners: total_winners,
        total_prize_amount: winners.sum { |ticket| ticket.prize_amount || 0 }
      )

      # Distribute prizes to winners
      distribute_prizes(draw, winners)

      # Update lottery game statistics
      update_game_statistics(lottery_game, draw)

      # Schedule next draw if game is still active
      if lottery_game.active?
        schedule_next_draw(lottery_game)
      end

      # Notify all participants about results
      notify_participants(draw)

      Rails.logger.info "Successfully completed draw #{draw.id} with #{total_winners} winners"
    end

  rescue StandardError => e
    Rails.logger.error "Failed to execute draw #{draw_id}: #{e.message}"
    draw.update!(status: "failed", error_message: e.message) if draw
    raise e
  end

  private

  def generate_winning_numbers(lottery_game)
    min_num = lottery_game.number_range_min
    max_num = lottery_game.number_range_max
    quantity = lottery_game.numbers_to_select

    # Use cryptographically secure random number generation
    numbers = []
    available_numbers = (min_num..max_num).to_a

    quantity.times do
      index = SecureRandom.random_number(available_numbers.length)
      numbers << available_numbers.delete_at(index)
    end

    numbers.sort
  end

  def determine_winners(draw)
    winning_numbers = draw.winning_numbers
    lottery_game = draw.lottery_game
    min_matches = lottery_game.min_matches_to_win || 3

    winners = []

    draw.tickets.find_each do |ticket|
      ticket_numbers = ticket.numbers_array
      matches = (ticket_numbers & winning_numbers).length

      if matches >= min_matches
        prize_amount = calculate_prize_amount(lottery_game, draw, matches)
        ticket.update!(
          status: :won,
          prize_amount: prize_amount,
          matches: matches
        )
        winners << ticket
      else
        ticket.update!(status: :lost, matches: matches)
      end
    end

    winners
  end

  def calculate_prize_amount(lottery_game, draw, matches)
    case lottery_game.winner_selection
    when "single_winner"
      calculate_single_winner_prize(lottery_game, draw, matches)
    when "multiple_winners"
      calculate_multiple_winner_prize(lottery_game, draw, matches)
    when "tiered_system"
      calculate_tiered_prize(lottery_game, draw, matches)
    else
      lottery_game.ticket_price * 2 # Default fallback
    end
  end

  def calculate_single_winner_prize(lottery_game, draw, matches)
    # In single winner mode, highest match count gets the full prize pool
    total_prize_pool = draw.jackpot_amount

    # Apply percentage based on match count
    percentage = case matches
    when lottery_game.numbers_to_select
      0.8 # Perfect match gets 80%
    when lottery_game.numbers_to_select - 1
      0.15 # One off gets 15%
    else
      0.05 # Other matches get 5%
    end

    total_prize_pool * percentage
  end

  def calculate_multiple_winner_prize(lottery_game, draw, matches)
    # In multiple winner mode, prize is split among all winners
    total_winners = draw.tickets.where(status: :won).count
    return 0 if total_winners == 0

    total_prize_pool = draw.jackpot_amount
    total_prize_pool / total_winners
  end

  def calculate_tiered_prize(lottery_game, draw, matches)
    # Tiered system with different percentages for different match levels
    total_prize_pool = draw.jackpot_amount

    percentage = case matches
    when lottery_game.numbers_to_select
      lottery_game.first_place_percentage || 0.6
    when lottery_game.numbers_to_select - 1
      lottery_game.second_place_percentage || 0.25
    when lottery_game.numbers_to_select - 2
      lottery_game.third_place_percentage || 0.15
    else
      0.05 # Consolation prize
    end

    # Count winners in this tier to split the tier prize
    tier_winners = draw.tickets.where(matches: matches, status: :won).count
    return 0 if tier_winners == 0

    tier_prize_pool = total_prize_pool * percentage
    tier_prize_pool / tier_winners
  end

  def distribute_prizes(draw, winners)
    winners.each do |ticket|
      next unless ticket.prize_amount && ticket.prize_amount > 0

      # Create payment record for the prize
      payment = ticket.user.payments.create!(
        amount: ticket.prize_amount,
        payment_type: "prize_payout",
        status: "completed",
        processed_at: Time.current,
        description: "Prize from #{draw.lottery_game.name} - Draw ##{draw.id}"
      )

      # Credit user's account balance
      ticket.user.add_funds!(ticket.prize_amount)

      # Handle tax implications for large prizes
      if ticket.prize_amount >= 600
        create_tax_document(ticket, draw)
      end

      # Log the payout
      PayoutLog.create!(
        user: ticket.user,
        lottery: draw.lottery_game.lottery, # Legacy compatibility
        amount: ticket.prize_amount,
        payout_date: Time.current,
        description: "Draw game prize payout"
      )
    end
  end

  def create_tax_document(ticket, draw)
    # Create tax document for prizes >= $600 (IRS requirement)
    # This would integrate with a tax document generation system
    tax_doc_params = {
      user: ticket.user,
      prize_amount: ticket.prize_amount,
      tax_year: Date.current.year,
      game_type: "draw_game",
      game_name: draw.lottery_game.name,
      win_date: draw.drawn_at,
      draw_id: draw.id,
      ticket_id: ticket.id
    }

    # TaxDocument.create!(tax_doc_params) # Would be implemented separately
    Rails.logger.info "Tax document needed for user #{ticket.user.id}, prize: $#{ticket.prize_amount}"
  end

  def update_game_statistics(lottery_game, draw)
    # Update game-level statistics
    total_revenue = draw.tickets.sum(:cost)
    total_prizes = draw.tickets.where(status: :won).sum(:prize_amount)

    # This could update a statistics table or cache
    Rails.cache.write("lottery_game_#{lottery_game.id}_last_draw_revenue", total_revenue, expires_in: 1.week)
    Rails.cache.write("lottery_game_#{lottery_game.id}_last_draw_prizes", total_prizes, expires_in: 1.week)
  end

  def schedule_next_draw(lottery_game)
    # Schedule the next draw based on the game's frequency
    next_draw_time = Time.current + lottery_game.draw_frequency_minutes.minutes

    # Don't create if one already exists
    return if lottery_game.draws.where(draw_date: next_draw_time).exists?

    next_draw = lottery_game.draws.create!(
      draw_date: next_draw_time,
      jackpot_amount: lottery_game.current_prize_pool,
      status: :scheduled
    )

    # Schedule the job to execute this draw
    DrawExecutionJob.set(wait_until: next_draw_time).perform_later(next_draw.id)
  end

  def notify_participants(draw)
    # Send notifications to all participants about the draw results
    draw.tickets.includes(:user).find_each do |ticket|
      if ticket.won?
        # Notify winners
        WinnerNotificationJob.perform_later(ticket.id)
      else
        # Optionally notify non-winners (could be configurable)
        # DrawResultNotificationJob.perform_later(ticket.id)
      end
    end

    # Broadcast real-time updates via ActionCable
    ActionCable.server.broadcast(
      "lottery_game_#{draw.lottery_game.id}",
      {
        type: "draw_completed",
        draw_id: draw.id,
        winning_numbers: draw.winning_numbers,
        total_winners: draw.total_winners,
        total_prize_amount: draw.total_prize_amount,
        next_draw_time: draw.lottery_game.next_draw_time
      }
    )
  end
end
