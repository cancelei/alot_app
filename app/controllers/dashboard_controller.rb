class DashboardController < ApplicationController
  def index
    # Get the jackpot lottery (lottery with highest current payout)
    @jackpot_lottery = Lottery.active_lotteries.order(current_payout: :desc).first

    # Get all active lotteries
    @active_lotteries = Lottery.active_lotteries.order(created_at: :desc)

    # Get the player's bets
    @bets = current_user.bets.includes(:lottery).order(created_at: :desc)

    # Get the player's pending bets
    @pending_bets = @bets.pending_bets

    # Get the player's winning bets
    @winning_bets = @bets.won_bets

    # Get the player's feature requests
    @feature_requests = current_user.feature_requests.order(created_at: :desc).limit(5)
  end
end
