class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    # American Lottery System Statistics
    @lottery_game_stats = {
      total_games: LotteryGame.count,
      active_games: LotteryGame.active_games.count,
      rapid_games: LotteryGame.rapid_games.count,
      official_games: LotteryGame.official_games.count,
      custom_games: LotteryGame.custom_games.count
    }

    @instant_game_stats = {
      total_games: InstantGame.count,
      active_games: InstantGame.active_games.count,
      total_tickets_sold: ScratchOff.count,
      total_instant_revenue: ScratchOff.joins(:instant_game).sum("instant_games.ticket_price") || 0,
      total_instant_prizes: ScratchOff.winning_tickets.sum(:prize_amount) || 0
    }

    @user_stats = {
      total_users: User.count,
      verified_users: User.joins(:identity_verification).where(identity_verifications: { status: :verified }).count,
      active_today: User.where("updated_at > ?", 24.hours.ago).count, # Using updated_at as proxy for activity
      self_excluded: User.where(self_excluded: true).count
    }

    @revenue_stats = {
      total_ticket_sales: Ticket.joins(:lottery_game).sum("lottery_games.ticket_price") || 0,
      total_instant_sales: ScratchOff.joins(:instant_game).sum("instant_games.ticket_price") || 0,
      total_platform_revenue: calculate_platform_revenue,
      total_prizes_paid: (Ticket.winning_tickets.sum(:prize_amount) || 0) + (ScratchOff.winning_tickets.sum(:prize_amount) || 0)
    }

    # Legacy statistics for backward compatibility
    statistics_service = LotteryStatisticsService.new if defined?(LotteryStatisticsService)
    @platform_stats = statistics_service&.platform_statistics || {}

    @total_lotteries = Lottery.count
    @active_lotteries = Lottery.active.count
    @draft_lotteries = Lottery.draft.count
    @ended_lotteries = Lottery.ended.count

    @total_bets = Bet.count
    @total_bet_amount = Bet.sum(:amount) || 0
    @pending_bets = Bet.pending_bets.count if Bet.respond_to?(:pending_bets)
    @won_bets = Bet.won_bets.count if Bet.respond_to?(:won_bets)
    @lost_bets = Bet.lost_bets.count if Bet.respond_to?(:lost_bets)

    # Get feature request statistics
    @total_feature_requests = FeatureRequest.count
    @pending_feature_requests = FeatureRequest.pending_review.count
    @approved_feature_requests = FeatureRequest.approved.count
    @rejected_feature_requests = FeatureRequest.rejected.count
    @shipped_feature_requests = FeatureRequest.shipped.count

    # Recent activity for new American lottery system
    @recent_lottery_games = LotteryGame.order(created_at: :desc).limit(5)
    @recent_instant_games = InstantGame.order(created_at: :desc).limit(5)
    @recent_tickets = Ticket.includes(:user, :lottery_game).order(purchase_date: :desc).limit(10)
    @recent_scratch_offs = ScratchOff.includes(:user, :instant_game).order(purchase_date: :desc).limit(10)
    @recent_winners = get_recent_winners
    @upcoming_draws = Draw.includes(:lottery_game).where("draw_date > ?", Time.current).order(:draw_date).limit(5)

    # State-specific statistics (users only - games are not state-specific)
    @state_stats = StateJurisdiction.active.includes(:users).map do |state|
      {
        state: state,
        state_name: state.state_name,
        user_count: state.users.count,
        verified_users: state.users.joins(:identity_verification).where(identity_verifications: { status: :verified }).count
      }
    end

    # Legacy activity (maintain backward compatibility)
    if statistics_service
      recent_activity = statistics_service.recent_activity
      @recent_bets = recent_activity[:recent_bets]
      @recent_payouts = recent_activity[:recent_payouts]
      @recent_players = recent_activity[:recent_players]
      @top_performing_lotteries = statistics_service.lottery_performance.limit(5)
      @betting_trends = statistics_service.betting_trends
    end

    @recent_lotteries = Lottery.order(created_at: :desc).limit(5)
    @recent_feature_requests = FeatureRequest.order(created_at: :desc).limit(5)
    @lottery_game_requests = FeatureRequest.lottery_games.order(created_at: :desc).limit(5) if FeatureRequest.respond_to?(:lottery_games)

    # Set refresh URL for Turbo Stream updates
    @refresh_url = admin_dashboard_path(format: :turbo_stream)

    # Handle Turbo Stream format for AJAX updates
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def calculate_platform_revenue
    lottery_revenue = LotteryGame.joins(:tickets).sum("lottery_games.ticket_price") * 0.1 # Assume 10% platform fee
    instant_revenue = InstantGame.joins(:scratch_offs).sum("instant_games.ticket_price") * 0.3 # Assume 30% platform fee
    lottery_revenue + instant_revenue
  end



  def get_recent_winners
    lottery_winners = Ticket.winning_tickets.includes(:user, :lottery_game).order(updated_at: :desc).limit(5)
    instant_winners = ScratchOff.winning_tickets.includes(:user, :instant_game).order(updated_at: :desc).limit(5)

    (lottery_winners + instant_winners).sort_by(&:updated_at).reverse.first(10)
  end
end
