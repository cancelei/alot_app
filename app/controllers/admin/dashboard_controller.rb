class Admin::DashboardController < ApplicationController
  before_action :require_admin

  def index
    # Use LotteryStatisticsService to get platform statistics
    statistics_service = LotteryStatisticsService.new
    @platform_stats = statistics_service.platform_statistics

    # Get lottery statistics
    @total_lotteries = @platform_stats[:total_lotteries]
    @active_lotteries = @platform_stats[:active_lotteries]
    @draft_lotteries = Lottery.draft.count
    @ended_lotteries = Lottery.ended.count

    # Get bet statistics
    @total_bets = @platform_stats[:total_bets]
    @total_bet_amount = @platform_stats[:total_bet_amount]
    @pending_bets = Bet.pending_bets.count
    @won_bets = Bet.won_bets.count
    @lost_bets = Bet.lost_bets.count

    # Get feature request statistics
    @total_feature_requests = FeatureRequest.count
    @pending_feature_requests = FeatureRequest.pending_review.count
    @approved_feature_requests = FeatureRequest.approved.count
    @rejected_feature_requests = FeatureRequest.rejected.count
    @shipped_feature_requests = FeatureRequest.shipped.count

    # Get recent activity
    recent_activity = statistics_service.recent_activity
    @recent_bets = recent_activity[:recent_bets]
    @recent_payouts = recent_activity[:recent_payouts]
    @recent_players = recent_activity[:recent_players]

    # Get recent lotteries
    @recent_lotteries = Lottery.order(created_at: :desc).limit(5)

    # Get recent feature requests
    @recent_feature_requests = FeatureRequest.order(created_at: :desc).limit(5)

    # Get lottery game feature requests
    @lottery_game_requests = FeatureRequest.lottery_games.order(created_at: :desc).limit(5)

    # Get lottery performance
    @top_performing_lotteries = statistics_service.lottery_performance.limit(5)

    # Get betting trends
    @betting_trends = statistics_service.betting_trends

    # Set refresh URL for Turbo Stream updates
    @refresh_url = admin_dashboard_path(format: :turbo_stream)

    # Handle Turbo Stream format for AJAX updates
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
