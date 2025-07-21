module LotteryHelper
  # Format odds as a percentage
  def format_odds(lottery)
    return "N/A" unless lottery.odds_json.present? && lottery.odds_json["win_probability"].present?

    win_probability = lottery.odds_json["win_probability"].to_f
    "#{(win_probability * 100).round(2)}%"
  end

  # Format payout strategy in a human-readable way
  def format_payout_strategy(lottery)
    case lottery.payout_strategy
    when "fixed_multiplier"
      "Fixed Multiplier (2x)"
    when "progressive"
      "Progressive (1.5x + pool)"
    when "jackpot"
      "Jackpot (10x)"
    else
      lottery.payout_strategy.to_s.humanize
    end
  end

  # Format lottery status with appropriate color class
  def lottery_status_badge(lottery)
    case lottery.status
    when "draft"
      content_tag(:span, "Draft", class: "badge bg-gray-500")
    when "active"
      content_tag(:span, "Active", class: "badge bg-green-500")
    when "paused"
      content_tag(:span, "Paused", class: "badge bg-yellow-500")
    when "ended"
      content_tag(:span, "Ended", class: "badge bg-red-500")
    else
      content_tag(:span, lottery.status.to_s.humanize, class: "badge bg-blue-500")
    end
  end

  # Format current payout amount
  def format_payout(amount)
    number_to_currency(amount, precision: 2)
  end

  # Display info tooltip for transparency
  def info_tooltip(content)
    content_tag(:span, class: "relative inline-block ml-1 cursor-help") do
      concat(content_tag(:i, nil, class: "fas fa-info-circle text-blue-500"))
      concat(content_tag(:div, content, class: "tooltip absolute hidden group-hover:block bg-gray-800 text-white p-2 rounded text-xs w-64 z-10 bottom-full left-1/2 transform -translate-x-1/2 -translate-y-2"))
    end
  end

  # Generate a verification link for a bet
  def verification_link(bet)
    # In MVP, this would link to a page explaining the verification process
    # In Phase 2, this would link to the actual blockchain explorer
    link_to "Verify on Chain", "#", class: "text-blue-500 underline", data: { turbo_frame: "verification_modal", action: "click->modal#open" }
  end
end
