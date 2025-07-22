class InstantGamesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_onboarding_complete
  before_action :set_instant_game, only: [ :show, :purchase ]

  def index
    @instant_games = InstantGame.active.includes(:scratch_offs)

    # Filter by price if specified
    if params[:price].present?
      price_filter = params[:price].to_f
      case price_filter
      when 1.0
        @instant_games = @instant_games.where(ticket_price: 1.0)
      when 5.0
        @instant_games = @instant_games.where(ticket_price: 5.0)
      when 10.0
        @instant_games = @instant_games.where("ticket_price >= ?", 10.0)
      end
    end

    # Sort by ticket price and then by tickets remaining
    @instant_games = @instant_games.order(:ticket_price, :remaining_tickets)
  end

  def show
    @instant_game = InstantGame.find(params[:id])
    @user_scratch_offs = current_user.scratch_offs.where(instant_game: @instant_game).recent.limit(10)

    # Parse prize structure for display
    @prize_structure = parse_prize_structure(@instant_game.prize_structure)

    # Calculate game statistics
    @tickets_sold = @instant_game.total_tickets - @instant_game.remaining_tickets
    @completion_percentage = (@tickets_sold.to_f / @instant_game.total_tickets * 100).round(1)

    # Check if user can purchase
    @can_purchase = @instant_game.can_purchase? && current_user.can_purchase_tickets?
  end

  def purchase
    unless @instant_game.can_purchase?
      redirect_to @instant_game, alert: "This game is not available for purchase."
      return
    end

    unless current_user.can_purchase_tickets?
      redirect_to @instant_game, alert: "You are not eligible to purchase tickets at this time."
      return
    end

    # Check user's balance or payment method
    if current_user.account_balance < @instant_game.ticket_price
      redirect_to @instant_game, alert: "Insufficient funds. Please add money to your account."
      return
    end

    begin
      # Create scratch-off ticket
      @scratch_off = @instant_game.purchase_ticket!(current_user)

      if @scratch_off.persisted?
        # Deduct from user's account (simplified - in production, use proper payment processing)
        current_user.update!(account_balance: current_user.account_balance - @instant_game.ticket_price)

        redirect_to scratch_off_path(@scratch_off), notice: "Ticket purchased successfully! Time to scratch and win!"
      else
        redirect_to @instant_game, alert: "Unable to purchase ticket. Please try again."
      end
    rescue StandardError => e
      Rails.logger.error "Instant game purchase error: #{e.message}"
      redirect_to @instant_game, alert: "An error occurred while purchasing your ticket. Please try again."
    end
  end

  private

  def set_instant_game
    @instant_game = InstantGame.find(params[:id])
  end

  def ensure_onboarding_complete
    unless current_user.fully_verified?
      redirect_to onboarding_path, alert: "Please complete your account verification to play instant games."
    end
  end

  def parse_prize_structure(prize_structure_json)
    return [] if prize_structure_json.blank?

    begin
      structure = prize_structure_json.is_a?(String) ? JSON.parse(prize_structure_json) : prize_structure_json
      return [] unless structure.is_a?(Array)

      structure.map do |prize|
        {
          amount: prize["amount"].to_f,
          quantity: prize["quantity"].to_i,
          odds: prize["odds"].to_f
        }
      end.sort_by { |p| -p[:amount] }
    rescue JSON::ParserError, NoMethodError
      []
    end
  end
end
