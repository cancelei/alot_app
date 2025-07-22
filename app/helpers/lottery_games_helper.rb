module LotteryGamesHelper
  def game_color(game_type)
    case game_type.to_s
    when "rapid"
      "red"
    when "hourly"
      "orange"
    when "daily"
      "blue"
    when "weekly"
      "purple"
    when "progressive"
      "green"
    else
      "gray"
    end
  end

  def time_until_draw(game)
    return "Draw Ended" unless game.is_active?

    next_draw = game.next_draw_time
    return "TBD" unless next_draw

    time_diff = next_draw - Time.current
    return "Drawing Now!" if time_diff <= 0

    if time_diff < 1.hour
      minutes = (time_diff / 60).to_i
      "#{minutes}m"
    elsif time_diff < 1.day
      hours = (time_diff / 1.hour).to_i
      minutes = ((time_diff % 1.hour) / 60).to_i
      "#{hours}h #{minutes}m"
    else
      days = (time_diff / 1.day).to_i
      hours = ((time_diff % 1.day) / 1.hour).to_i
      "#{days}d #{hours}h"
    end
  end

  def format_jackpot(amount)
    if amount >= 1_000_000
      "$#{(amount / 1_000_000.0).round(1)}M"
    elsif amount >= 1_000
      "$#{(amount / 1_000.0).round(0)}K"
    else
      "$#{amount.to_i}"
    end
  end

  def game_type_icon(game_type)
    case game_type.to_s
    when "rapid"
      "⚡"
    when "hourly"
      "⏰"
    when "daily"
      "📅"
    when "weekly"
      "🎰"
    when "progressive"
      "💎"
    else
      "🎲"
    end
  end

  def draw_frequency_text(game)
    case game.game_type
    when "rapid"
      "Every #{game.draw_frequency} minutes"
    when "hourly"
      "Every hour"
    when "daily"
      "Daily at 9 PM"
    when "weekly"
      "Weekly on Wednesdays"
    when "progressive"
      "Every #{game.draw_frequency / 1440} days"
    else
      "Every #{game.draw_frequency} minutes"
    end
  end

  def odds_text(game)
    # Calculate approximate odds based on number range and picks
    total_combinations = combination_count(game.number_range_max - game.number_range_min + 1, game.numbers_to_pick)

    if game.bonus_ball?
      bonus_range = game.bonus_range_max - game.bonus_range_min + 1
      total_combinations *= bonus_range
    end

    "1 in #{number_with_delimiter(total_combinations)}"
  end

  def winning_numbers_display(numbers_string)
    return [] if numbers_string.blank?

    begin
      numbers = JSON.parse(numbers_string)
      numbers.is_a?(Array) ? numbers : []
    rescue JSON::ParserError
      []
    end
  end

  def ticket_status_badge(ticket)
    case ticket.status
    when "pending"
      content_tag :span, "Pending", class: "px-2 py-1 bg-yellow-100 text-yellow-800 text-xs font-semibold rounded-full"
    when "active"
      content_tag :span, "Active", class: "px-2 py-1 bg-blue-100 text-blue-800 text-xs font-semibold rounded-full"
    when "won"
      content_tag :span, "Winner!", class: "px-2 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full"
    when "lost"
      content_tag :span, "No Win", class: "px-2 py-1 bg-gray-100 text-gray-800 text-xs font-semibold rounded-full"
    when "claimed"
      content_tag :span, "Claimed", class: "px-2 py-1 bg-purple-100 text-purple-800 text-xs font-semibold rounded-full"
    else
      content_tag :span, ticket.status.humanize, class: "px-2 py-1 bg-gray-100 text-gray-800 text-xs font-semibold rounded-full"
    end
  end

  def prize_tier_name(matches, game)
    case matches
    when game.numbers_to_pick
      "Jackpot"
    when game.numbers_to_pick - 1
      "Second Prize"
    when game.numbers_to_pick - 2
      "Third Prize"
    else
      "Prize Tier #{matches}"
    end
  end

  private

  def combination_count(n, k)
    return 1 if k == 0 || k == n
    return 0 if k > n

    # Calculate C(n,k) = n! / (k! * (n-k)!)
    result = 1
    k = [ k, n - k ].min # Take advantage of symmetry

    (1..k).each do |i|
      result = result * (n - i + 1) / i
    end

    result
  end
end
