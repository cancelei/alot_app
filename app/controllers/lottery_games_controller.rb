class LotteryGamesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_onboarding_complete
  before_action :set_lottery_game, only: [ :show, :edit, :update, :destroy ]

  def index
    @lottery_games = LotteryGame.active.includes(:tickets, :draws)

    # Filter by game type if specified
    if params[:filter].present?
      case params[:filter]
      when "rapid"
        @lottery_games = @lottery_games.rapid
      when "hourly"
        @lottery_games = @lottery_games.hourly
      when "daily"
        @lottery_games = @lottery_games.daily
      when "weekly"
        @lottery_games = @lottery_games.weekly
      when "progressive"
        @lottery_games = @lottery_games.progressive
      end
    end

    # Sort by next draw time (soonest first)
    @lottery_games = @lottery_games.sort_by(&:next_draw_time).compact
  end

  def show
    @lottery_game = LotteryGame.find(params[:id])
    @recent_draws = @lottery_game.draws.completed.order(draw_date: :desc).limit(5)
    @user_tickets = current_user.tickets.where(lottery_game: @lottery_game).order(created_at: :desc).limit(10)
    @next_draw = @lottery_game.draws.upcoming.first

    # Calculate game statistics
    @total_tickets_sold = @lottery_game.tickets.count
    @current_prize_pool = @lottery_game.current_prize_pool || @lottery_game.base_jackpot || 10000
    @biggest_win = @lottery_game.tickets.where.not(prize_amount: nil).maximum(:prize_amount) || 0
    @total_winners = @lottery_game.tickets.winning_tickets.count

    # Check if user can purchase tickets
    @can_purchase = @lottery_game.active? &&
                   current_user.fully_verified? &&
                   current_user.can_purchase_tickets? &&
                   (@next_draw.present? && @next_draw.draw_date > Time.current)

    # Time calculations
    @time_until_draw = @next_draw&.draw_date ? (@next_draw.draw_date - Time.current).to_i : nil

    # User account info for purchase validation
    @user_balance = current_user.account_balance || 0
    @base_ticket_cost = @lottery_game.ticket_price || 2.0
  end

  private

  def set_lottery_game
    @lottery_game = LotteryGame.find(params[:id])
  end

  def ensure_onboarding_complete
    unless current_user.fully_verified?
      redirect_to onboarding_path, alert: "Please complete your account verification to play lottery games."
    end
  end

  def lottery_game_params
    params.require(:lottery_game).permit(:name, :description, :game_type, :draw_frequency,
                                        :ticket_price, :numbers_to_pick, :number_range_min,
                                        :number_range_max, :bonus_ball, :multiplier_available,
                                        :multiplier_cost, :prize_pool_percentage, :jackpot_seed,
                                        :jackpot_increment, :winner_selection_mode, :pool_reset_rule,
                                        :max_jackpot, :is_active)
  end
end
