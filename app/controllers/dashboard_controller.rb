class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_onboarding_complete

  def index
    @user = current_user

    # Get active tickets and recent activity
    @active_tickets = current_user.tickets.active_tickets.includes(:lottery_game, :draw).limit(5)
    @recent_tickets = current_user.tickets.includes(:lottery_game, :draw).order(created_at: :desc).limit(10)

    # Get upcoming draws (using new lottery system)
    @upcoming_draws = LotteryGame.active.where("next_draw_at > ?", Time.current).order(:next_draw_at).limit(3)

    # Get all active lottery games for quick access
    @lottery_games = LotteryGame.active.order(:name)
    @jackpot_lottery = @lottery_games.order(current_jackpot: :desc).first
    @featured_lottery_games = @lottery_games.limit(3)
    @active_lottery_games = @lottery_games.limit(6)

    # Get recent payments and account activity
    @recent_payments = current_user.payments.order(created_at: :desc).limit(5)

    # Get active subscriptions
    @active_subscriptions = current_user.subscriptions.where(status: "active").includes(:lottery_game).limit(3)

    # Get winning tickets for recent winnings section
    @winning_tickets = current_user.tickets.winning_tickets.includes(:lottery_game).limit(5)

    # Calculate statistics
    @total_spent = current_user.total_spent
    @total_winnings = current_user.tickets.winning_tickets.sum(:prize_amount)
    @tickets_this_month = current_user.tickets.where("created_at >= ?", 1.month.ago).count

    # Get instant games for quick access
    @featured_instant_games = InstantGame.active.limit(3)

    # Get user's recent scratch-offs
    @recent_scratch_offs = current_user.scratch_offs.recent.limit(5)
  end

  private

  def ensure_onboarding_complete
    unless current_user.onboarding_complete?
      redirect_to onboarding_path, alert: "Please complete your account setup first."
    end
  end
end
