module InstantGamesHelper
  def instant_game_color(ticket_price)
    case ticket_price.to_f
    when 1.0
      "green"
    when 2.0..3.0
      "blue"
    when 4.0..5.0
      "purple"
    when 6.0..10.0
      "red"
    when 11.0..20.0
      "yellow"
    else
      "gray"
    end
  end

  def format_prize_amount(amount)
    if amount >= 1_000_000
      "$#{(amount / 1_000_000.0).round(1)}M"
    elsif amount >= 1_000
      "$#{(amount / 1_000.0).round(0)}K"
    else
      "$#{amount.to_i}"
    end
  end

  def scratch_off_status_badge(scratch_off)
    case scratch_off.status
    when "unscratched"
      content_tag :span, "Ready to Play", class: "px-3 py-1 bg-blue-100 text-blue-800 text-sm font-semibold rounded-full"
    when "scratched"
      if scratch_off.prize_amount && scratch_off.prize_amount > 0
        content_tag :span, "Winner! $#{number_with_delimiter(scratch_off.prize_amount.to_i)}", class: "px-3 py-1 bg-green-100 text-green-800 text-sm font-semibold rounded-full"
      else
        content_tag :span, "No Win", class: "px-3 py-1 bg-gray-100 text-gray-800 text-sm font-semibold rounded-full"
      end
    when "claimed"
      content_tag :span, "Prize Claimed", class: "px-3 py-1 bg-purple-100 text-purple-800 text-sm font-semibold rounded-full"
    else
      content_tag :span, scratch_off.status.humanize, class: "px-3 py-1 bg-gray-100 text-gray-800 text-sm font-semibold rounded-full"
    end
  end

  def remaining_tickets_color(game)
    percentage = (game.tickets_remaining.to_f / game.total_tickets * 100)

    if percentage > 50
      "text-green-600"
    elsif percentage > 20
      "text-yellow-600"
    else
      "text-red-600"
    end
  end

  def game_availability_status(game)
    if game.can_purchase?
      { status: "available", color: "green", text: "Available" }
    elsif game.tickets_remaining <= 0
      { status: "sold_out", color: "red", text: "Sold Out" }
    else
      { status: "inactive", color: "gray", text: "Inactive" }
    end
  end

  def prize_odds_text(odds)
    if odds >= 1
      "1 in #{odds.to_i}"
    else
      "1 in #{(1.0 / odds).round}"
    end
  end

  def scratch_pattern_class(index)
    patterns = [
      "bg-gradient-to-br from-gray-300 to-gray-400",
      "bg-gradient-to-br from-silver-300 to-silver-400",
      "bg-gradient-to-br from-gray-400 to-gray-500"
    ]
    patterns[index % patterns.length]
  end

  def winning_symbol_for_amount(amount)
    case amount.to_f
    when 0
      "❌"
    when 1.0..5.0
      "🍒"
    when 6.0..20.0
      "🔔"
    when 21.0..100.0
      "💎"
    when 101.0..1000.0
      "👑"
    when 1001.0..10000.0
      "🏆"
    else
      "💰"
    end
  end

  def scratch_animation_delay(index)
    "animation-delay: #{(index * 0.1)}s"
  end

  def total_possible_winnings(prize_structure)
    return 0 if prize_structure.blank?

    begin
      structure = prize_structure.is_a?(String) ? JSON.parse(prize_structure) : prize_structure
      return 0 unless structure.is_a?(Array)

      structure.sum { |prize| prize["amount"].to_f * prize["quantity"].to_i }
    rescue JSON::ParserError, NoMethodError
      0
    end
  end

  def expected_value(game)
    return 0 if game.prize_structure.blank?

    begin
      structure = game.prize_structure.is_a?(String) ? JSON.parse(game.prize_structure) : game.prize_structure
      return 0 unless structure.is_a?(Array)

      total_value = structure.sum { |prize| prize["amount"].to_f * prize["quantity"].to_i }
      (total_value / game.total_tickets * 100).round(1)
    rescue JSON::ParserError, NoMethodError
      0
    end
  end

  def format_completion_percentage(percentage)
    case percentage
    when 0..25
      { class: "text-green-600", text: "#{percentage}% sold" }
    when 26..50
      { class: "text-yellow-600", text: "#{percentage}% sold" }
    when 51..75
      { class: "text-orange-600", text: "#{percentage}% sold" }
    when 76..90
      { class: "text-red-600", text: "#{percentage}% sold - Limited!" }
    else
      { class: "text-red-700 font-bold", text: "#{percentage}% sold - Almost Gone!" }
    end
  end

  def instant_game_theme_class(game_name)
    case game_name.downcase
    when /lucky|star/
      "from-yellow-400 to-yellow-600"
    when /cash|money|dollar/
      "from-green-400 to-green-600"
    when /diamond|gem|jewel/
      "from-blue-400 to-blue-600"
    when /million|mega|super/
      "from-purple-400 to-purple-600"
    when /holiday|christmas|festive/
      "from-red-400 to-red-600"
    else
      "from-gray-400 to-gray-600"
    end
  end
end
