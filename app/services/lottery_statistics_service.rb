class LotteryStatisticsService
  # This service handles lottery statistics and analytics

  def initialize(time_period = 30.days)
    @time_period = time_period
  end

  # Get overall platform statistics
  def platform_statistics
    {
      total_lotteries: Lottery.count,
      active_lotteries: Lottery.active.count,
      total_bets: Bet.count,
      total_bet_amount: Bet.sum(:amount),
      total_payouts: PayoutLog.sum(:amount),
      total_players: User.player.count,
      active_players: active_players_count,
      win_rate: calculate_win_rate
    }
  end

  # Get lottery performance statistics
  def lottery_performance
    Lottery.select(
      "lotteries.*, " \
      "COUNT(DISTINCT bets.id) as bet_count, " \
      "SUM(bets.amount) as total_bet_amount, " \
      "COUNT(DISTINCT bets.user_id) as unique_players"
    )
    .left_joins(:bets)
    .group("lotteries.id")
    .order("total_bet_amount DESC")
  end

  # Get recent activity statistics
  def recent_activity
    {
      recent_bets: Bet.order(created_at: :desc).limit(10),
      recent_payouts: PayoutLog.order(created_at: :desc).limit(10),
      recent_players: User.player.order(created_at: :desc).limit(10)
    }
  end

  # Get betting trends over time
  def betting_trends
    # Daily bet counts for the time period
    daily_bets = Bet.where(created_at: @time_period.ago..)
      .group("DATE(created_at)")
      .count

    # Daily bet amounts for the time period
    daily_amounts = Bet.where(created_at: @time_period.ago..)
      .group("DATE(created_at)")
      .sum(:amount)

    # Combine the data
    dates = (daily_bets.keys + daily_amounts.keys).uniq.sort

    dates.map do |date|
      {
        date: date,
        count: daily_bets[date] || 0,
        amount: daily_amounts[date] || 0
      }
    end
  end

  # Get player statistics
  def player_statistics
    {
      top_players_by_bets: top_players_by_bets,
      top_players_by_wins: top_players_by_wins,
      player_retention: calculate_player_retention,
      new_players: User.player.where(created_at: @time_period.ago..).count
    }
  end

  private

  # Count active players (placed a bet in the time period)
  def active_players_count
    User.player
      .joins(:bets)
      .where(bets: { created_at: @time_period.ago.. })
      .distinct
      .count
  end

  # Calculate overall win rate
  def calculate_win_rate
    total_bets = Bet.confirmed_bets.count
    return 0 if total_bets == 0

    won_bets = Bet.won_bets.count
    (won_bets.to_f / total_bets) * 100
  end

  # Get top players by number of bets
  def top_players_by_bets
    User.player
      .select("users.*, COUNT(bets.id) as bet_count")
      .joins(:bets)
      .group("users.id")
      .order("bet_count DESC")
      .limit(10)
  end

  # Get top players by number of wins
  def top_players_by_wins
    User.player
      .select("users.*, COUNT(bets.id) as win_count")
      .joins(:bets)
      .where(bets: { result: :won })
      .group("users.id")
      .order("win_count DESC")
      .limit(10)
  end

  # Calculate player retention rate
  def calculate_player_retention
    # Players who placed bets in both the previous and current time periods
    previous_period = (@time_period * 2).ago..@time_period.ago
    current_period = @time_period.ago..Time.current

    previous_players = User.player
      .joins(:bets)
      .where(bets: { created_at: previous_period })
      .distinct

    retained_players = previous_players
      .joins(:bets)
      .where(bets: { created_at: current_period })
      .distinct
      .count

    previous_count = previous_players.count
    return 0 if previous_count == 0

    (retained_players.to_f / previous_count) * 100
  end
end
