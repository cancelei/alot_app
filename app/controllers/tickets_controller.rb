class TicketsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_can_purchase_tickets
  before_action :set_lottery_game, only: [ :new, :create, :quick_pick ]
  before_action :set_ticket, only: [ :show, :claim_prize ]

  def index
    @active_tickets = current_user.tickets.active_tickets.includes(:lottery_game, :draw).order(purchase_date: :desc)
    @recent_tickets = current_user.tickets.includes(:lottery_game, :draw).order(purchase_date: :desc).limit(20)
    @winning_tickets = current_user.tickets.winning_tickets.includes(:lottery_game, :draw).order(updated_at: :desc)

    @ticket_stats = {
      total_spent: current_user.total_spent,
      total_winnings: current_user.total_draw_winnings,
      active_count: @active_tickets.count,
      winning_count: @winning_tickets.count
    }
  end

  def show
    @draw = @ticket.draw
    @lottery_game = @ticket.lottery_game
    @can_claim = @ticket.can_claim_prize?
  end

  def new
    @ticket = @lottery_game.tickets.build
    @next_draw = @lottery_game.draws.upcoming.first
    @current_prize_pool = @lottery_game.current_prize_pool
    @time_until_draw = @lottery_game.time_until_next_draw

    # Set up number selection options
    @number_range = (@lottery_game.number_range_min..@lottery_game.number_range_max).to_a
    @numbers_to_select = @lottery_game.numbers_to_select
    @allows_quick_pick = @lottery_game.allows_quick_pick
    @allows_multi_draw = @lottery_game.allows_multi_draw
    @max_multi_draw = @lottery_game.max_multi_draw_count
  end

  def create
    # Validate that numbers are provided and valid
    unless params[:ticket][:numbers].present?
      redirect_to lottery_game_path(@lottery_game), alert: "Please select your numbers before purchasing."
      return
    end

    # Parse and validate numbers
    begin
      selected_numbers = JSON.parse(params[:ticket][:numbers])
    rescue JSON::ParserError
      redirect_to lottery_game_path(@lottery_game), alert: "Invalid number selection."
      return
    end

    # Validate number count
    if selected_numbers.length != @lottery_game.numbers_to_draw
      redirect_to lottery_game_path(@lottery_game), alert: "Please select exactly #{@lottery_game.numbers_to_draw} numbers."
      return
    end

    # Validate number range
    if selected_numbers.any? { |n| n < 1 || n > @lottery_game.max_number }
      redirect_to lottery_game_path(@lottery_game), alert: "Numbers must be between 1 and #{@lottery_game.max_number}."
      return
    end

    # Validate cost matches expected calculation
    expected_cost = calculate_ticket_cost(selected_numbers.length)
    provided_cost = params[:ticket][:cost].to_f

    if (expected_cost - provided_cost).abs > 0.01
      redirect_to lottery_game_path(@lottery_game), alert: "Price mismatch. Please try again."
      return
    end

    # Check user can afford the ticket
    unless current_user.can_spend?(expected_cost)
      redirect_to lottery_game_path(@lottery_game), alert: "Insufficient funds or spending limit exceeded."
      return
    end

    # Find or create next draw
    next_draw = @lottery_game.draws.upcoming.first
    unless next_draw
      redirect_to lottery_game_path(@lottery_game), alert: "No upcoming draws available."
      return
    end

    # Create ticket with transaction safety
    ActiveRecord::Base.transaction do
      # Deduct funds first
      current_user.decrement!(:account_balance, expected_cost)

      # Create ticket
      @ticket = current_user.tickets.create!(
        lottery_game: @lottery_game,
        draw: next_draw,
        numbers: selected_numbers,
        cost: expected_cost,
        purchase_date: Time.current,
        status: "active"
      )

      # Create payment record
      Payment.create!(
        user: current_user,
        ticket: @ticket,
        amount: expected_cost,
        payment_type: "ticket_purchase",
        status: "completed",
        processed_at: Time.current
      )

      # Update lottery game prize pool
      @lottery_game.increment!(:current_prize_pool, expected_cost * 0.7) # 70% goes to prize pool
    end

    redirect_to ticket_path(@ticket), notice: "Ticket purchased successfully! Your numbers: #{selected_numbers.sort.join(', ')}"

  rescue ActiveRecord::RecordInvalid => e
    redirect_to lottery_game_path(@lottery_game), alert: "Failed to purchase ticket: #{e.message}"
  rescue => e
    Rails.logger.error "Ticket purchase error: #{e.message}"
    redirect_to lottery_game_path(@lottery_game), alert: "An error occurred. Please try again."
  end

  def quick_pick
    @ticket_service = TicketPurchaseService.new(current_user, @lottery_game)

    # Generate quick pick numbers
    quick_pick_numbers = generate_quick_pick_numbers(@lottery_game)

    params_with_quick_pick = {
      numbers: quick_pick_numbers,
      multi_draw_count: params[:multi_draw_count] || 1,
      is_quick_pick: true
    }

    result = @ticket_service.purchase_ticket(params_with_quick_pick)

    if result[:success]
      @ticket = result[:ticket]
      redirect_to ticket_path(@ticket), notice: "Quick Pick ticket purchased successfully!"
    else
      redirect_to new_lottery_game_ticket_path(@lottery_game),
                  alert: result[:error]
    end
  end

  def claim_prize
    if @ticket.can_claim_prize?
      result = PrizeClaimService.new(@ticket).claim_prize

      if result[:success]
        redirect_to ticket_path(@ticket), notice: "Prize claimed successfully!"
      else
        redirect_to ticket_path(@ticket), alert: result[:error]
      end
    else
      redirect_to ticket_path(@ticket), alert: "This ticket cannot be claimed."
    end
  end

  # AJAX endpoint for real-time prize pool updates
  def prize_pool_update
    @lottery_game = LotteryGame.find(params[:lottery_game_id])

    render json: {
      current_prize_pool: @lottery_game.current_prize_pool,
      time_until_draw: @lottery_game.time_until_next_draw,
      tickets_sold: @lottery_game.total_tickets_sold
    }
  end

  private

  def set_lottery_game
    @lottery_game = LotteryGame.active_games.find(params[:lottery_game_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Lottery game not found or not available."
  end

  def set_ticket
    @ticket = current_user.tickets.find(params[:id])
  end

  def ensure_can_purchase_tickets
    unless current_user.can_purchase_tickets?
      redirect_to dashboard_path, alert: "You must complete verification to purchase tickets."
    end
  end

  def ticket_params
    params.require(:ticket).permit(:multi_draw_count, numbers: [])
  end

  def calculate_ticket_cost(num_selected)
    # Base cost multiplied by complexity factor
    # More numbers = higher cost but better odds
    base_cost = @lottery_game.ticket_price || 2.0
    min_numbers = @lottery_game.numbers_to_draw || 1

    complexity_multiplier = Math.pow(1.5, num_selected - min_numbers)
    (base_cost * complexity_multiplier).round(2)
  end

  def generate_quick_pick_numbers(lottery_game)
    available_numbers = (1..lottery_game.max_number).to_a
    selected_numbers = []

    lottery_game.numbers_to_draw.times do
      index = SecureRandom.random_number(available_numbers.length)
      selected_numbers << available_numbers.delete_at(index)
    end

    selected_numbers.sort
  end
end
