class TicketPurchaseService
  attr_reader :user, :lottery_game, :errors

  def initialize(user, lottery_game)
    @user = user
    @lottery_game = lottery_game
    @errors = []
  end

  def purchase_ticket(params)
    ActiveRecord::Base.transaction do
      # Validate purchase eligibility
      return failure("User cannot purchase tickets") unless validate_user_eligibility
      return failure("Game not available for purchase") unless validate_game_availability

      # Get or create upcoming draw
      draw = get_or_create_upcoming_draw
      return failure("No upcoming draw available") unless draw

      # Validate and process numbers
      numbers = process_numbers(params)
      return failure("Invalid number selection") unless numbers

      # Calculate costs
      multi_draw_count = [ params[:multi_draw_count].to_i, 1 ].max
      multi_draw_count = [ @lottery_game.max_multi_draw_count, multi_draw_count ].min if @lottery_game.max_multi_draw_count

      ticket_cost = @lottery_game.ticket_price
      total_cost = ticket_cost * multi_draw_count

      # Validate user can afford the purchase
      return failure("Insufficient funds") unless validate_funds(total_cost)
      return failure("Purchase exceeds spending limits") unless validate_spending_limits(total_cost)

      # Create the ticket(s)
      tickets = create_tickets(draw, numbers, multi_draw_count, ticket_cost, params[:is_quick_pick])
      return failure("Failed to create tickets") if tickets.empty?

      # Process payment
      payment_result = process_payment(total_cost, tickets)
      return failure(payment_result[:error]) unless payment_result[:success]

      # Update user activity
      @user.update_last_activity!

      # Update prize pool
      update_prize_pool(total_cost)

      success(tickets.first, "Ticket purchased successfully")
    end
  rescue StandardError => e
    Rails.logger.error "Ticket purchase failed: #{e.message}"
    failure("Purchase failed: #{e.message}")
  end

  private

  def validate_user_eligibility
    return false unless @user.can_purchase_tickets?
    return false if @user.self_excluded?
    return false unless @user.state_allows_online_lottery?

    true
  end

  def validate_game_availability
    return false unless @lottery_game.active?
    return false unless @lottery_game.can_purchase_tickets?

    # Check if max players limit is reached
    if @lottery_game.max_players_per_draw.present?
      upcoming_draw = @lottery_game.draws.upcoming.first
      if upcoming_draw && upcoming_draw.tickets.count >= @lottery_game.max_players_per_draw
        return false
      end
    end

    true
  end

  def get_or_create_upcoming_draw
    upcoming_draw = @lottery_game.draws.upcoming.first

    unless upcoming_draw
      # Create next draw if none exists
      @lottery_game.schedule_next_draw!
      upcoming_draw = @lottery_game.draws.upcoming.first
    end

    # Check if draw is still accepting entries (not too close to draw time)
    if upcoming_draw
      time_until_draw = (upcoming_draw.draw_date - Time.current).to_i
      entry_cutoff = 5.minutes.to_i # Stop accepting entries 5 minutes before draw

      return nil if time_until_draw < entry_cutoff
    end

    upcoming_draw
  end

  def process_numbers(params)
    numbers = params[:numbers]

    if params[:is_quick_pick]
      # Numbers already generated for quick pick
      return numbers if numbers.is_a?(Array) && numbers.length == @lottery_game.numbers_to_select
    else
      # Validate manually selected numbers
      return nil unless numbers.is_a?(Array)
      return nil unless numbers.length == @lottery_game.numbers_to_select

      # Convert to integers and validate range
      numbers = numbers.map(&:to_i)
      min_num = @lottery_game.number_range_min
      max_num = @lottery_game.number_range_max

      return nil unless numbers.all? { |num| num >= min_num && num <= max_num }
      return nil unless numbers.uniq.length == numbers.length # No duplicates
    end

    numbers.sort
  end

  def validate_funds(total_cost)
    @user.account_balance >= total_cost
  end

  def validate_spending_limits(total_cost)
    @user.can_spend?(total_cost)
  end

  def create_tickets(draw, numbers, multi_draw_count, ticket_cost, is_quick_pick)
    tickets = []
    current_draw = draw

    multi_draw_count.times do |i|
      # For multi-draw, we need to get the appropriate draw
      if i > 0
        next_draw_time = current_draw.draw_date + @lottery_game.draw_frequency_minutes.minutes
        current_draw = @lottery_game.draws.find_or_create_by(draw_date: next_draw_time) do |new_draw|
          new_draw.jackpot_amount = @lottery_game.current_prize_pool
          new_draw.status = :scheduled
        end
      end

      ticket = @lottery_game.tickets.create!(
        user: @user,
        draw: current_draw,
        numbers: numbers,
        purchase_date: Time.current,
        cost: ticket_cost,
        status: :active,
        is_quick_pick: is_quick_pick || false
      )

      tickets << ticket
    end

    tickets
  end

  def process_payment(total_cost, tickets)
    # Deduct from user's account balance
    if @user.account_balance >= total_cost
      @user.increment!(:account_balance, -total_cost)

      # Create payment record
      payment = @user.payments.create!(
        amount: total_cost,
        payment_type: "ticket_purchase",
        status: "completed",
        processed_at: Time.current,
        description: "Lottery ticket purchase - #{@lottery_game.name}"
      )

      # Associate payment with tickets
      tickets.each { |ticket| ticket.update!(payment: payment) }

      { success: true, payment: payment }
    else
      { success: false, error: "Insufficient account balance" }
    end
  end

  def update_prize_pool(ticket_sales_amount)
    # Add contribution to the prize pool
    contribution_amount = ticket_sales_amount * @lottery_game.contribution_rate

    # This could be handled by updating a cached value or triggering a job
    PrizePoolUpdateJob.perform_later(@lottery_game.id, contribution_amount)
  end

  def success(ticket, message)
    {
      success: true,
      ticket: ticket,
      message: message
    }
  end

  def failure(error_message)
    @errors << error_message
    {
      success: false,
      error: error_message,
      ticket: nil
    }
  end
end
