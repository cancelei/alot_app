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
    @avg_bet_amount = Bet.average(:amount) || 0
    @confirmed_bets = Bet.confirmed_bets.count
    @win_rate = LotteryStatisticsService.new.calculate_win_rate

    # Get bet statistics by result for chart
    @won_bets_count = Bet.won_bets.count
    @lost_bets_count = Bet.lost_bets.count
    @pending_bets_count = Bet.pending_bets.count

    # Get recent bets for table
    @recent_bets = Bet.includes(:player, :lottery).order(created_at: :desc).limit(10)

    # Get bets by date (last 30 days) for trends
    @bets_by_date = Bet.where(created_at: 30.days.ago..)
      .group("DATE(created_at)")
      .count

    # Get daily bet count and volume for the chart
    @daily_bet_count = Bet.where(created_at: 1.day.ago..).count
    @daily_bet_volume = Bet.where(created_at: 1.day.ago..).sum(:amount)

    # Get bets by lottery
    @bets_by_lottery = Lottery.select("lotteries.*, COUNT(bets.id) as bet_count")
      .joins(:bets)
      .group("lotteries.id")
      .order("bet_count DESC")
  end

  def payouts
    # Get payout statistics
    @total_payouts = PayoutLog.count
    @total_payout_amount = PayoutLog.sum(:amount) || 0
    @avg_payout_amount = PayoutLog.average(:amount) || 0
    @total_reinvestment_amount = PayoutLog.where(reinvested: true).sum(:amount) || 0

    # Get recent payouts for table
    @recent_payouts = PayoutLog.includes(:player, :lottery).order(created_at: :desc).limit(10)

    # Get payouts by date (last 30 days)
    @payouts_by_date = PayoutLog.where(created_at: 30.days.ago..)
      .group("DATE(created_at)")
      .sum(:amount)

    # Get monthly payout and reinvestment amounts for the chart
    @monthly_payout_amount = PayoutLog.where(created_at: 1.month.ago..).sum(:amount)
    @monthly_reinvestment_amount = PayoutLog.where(created_at: 1.month.ago.., reinvested: true).sum(:amount)

    # Get payouts by lottery for the pie chart
    lottery_payouts = Lottery.select("lotteries.name, SUM(payout_logs.amount) as payout_amount")
      .joins(:payout_logs)
      .group("lotteries.id, lotteries.name")
      .order("payout_amount DESC")
      .limit(6)

    @lottery_names = lottery_payouts.map(&:name)
    @lottery_payout_amounts = lottery_payouts.map(&:payout_amount)
  end
end
