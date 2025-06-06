class Admin::ReportsController < ApplicationController
  before_action :require_admin

  def players
    # Get player statistics
    @total_players = User.player.count
    @active_players = User.player.joins(:bets).where(bets: { created_at: 30.days.ago.. }).distinct.count
    @new_players = User.player.where(created_at: 30.days.ago..).count

    # Get top players by bet amount
    @top_players_by_amount = User.player
      .select("users.*, SUM(bets.amount) as total_bet_amount")
      .joins(:bets)
      .group("users.id")
      .order("total_bet_amount DESC")
      .limit(10)

    # Get top players by win count
    @top_players_by_wins = User.player
      .select("users.*, COUNT(bets.id) as win_count")
      .joins(:bets)
      .where(bets: { result: :won })
      .group("users.id")
      .order("win_count DESC")
      .limit(10)
  end

  def bets
    # Get bet statistics
    @total_bets = Bet.count
    @total_bet_amount = Bet.sum(:amount)
    @average_bet_amount = Bet.average(:amount)

    # Get bet statistics by result
    @won_bets = Bet.won_bets.count
    @lost_bets = Bet.lost_bets.count
    @pending_bets = Bet.pending_bets.count
    @failed_bets = Bet.failed_bets.count

    # Get bets by date (last 30 days)
    @bets_by_date = Bet.where(created_at: 30.days.ago..)
      .group("DATE(created_at)")
      .count

    # Get bets by lottery
    @bets_by_lottery = Lottery.select("lotteries.*, COUNT(bets.id) as bet_count")
      .joins(:bets)
      .group("lotteries.id")
      .order("bet_count DESC")
  end

  def payouts
    # Get payout statistics
    @total_payouts = PayoutLog.count
    @total_payout_amount = PayoutLog.sum(:amount)
    @average_payout_amount = PayoutLog.average(:amount)

    # Get payouts by date (last 30 days)
    @payouts_by_date = PayoutLog.where(created_at: 30.days.ago..)
      .group("DATE(created_at)")
      .sum(:amount)

    # Get top payouts
    @top_payouts = PayoutLog.order(amount: :desc).limit(10)

    # Get payouts by lottery
    @payouts_by_lottery = Lottery.select("lotteries.*, SUM(payout_logs.amount) as payout_amount")
      .joins(:payout_logs)
      .group("lotteries.id")
      .order("payout_amount DESC")
  end
end
