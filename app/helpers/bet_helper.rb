module BetHelper
  # Format bet status with appropriate color badge
  def bet_status_badge(bet)
    if !bet.confirmed_on_chain?
      content_tag(:span, "Pending Confirmation", class: "badge bg-yellow-500")
    elsif bet.won?
      content_tag(:span, "Won", class: "badge bg-green-500")
    elsif bet.lost?
      content_tag(:span, "Lost", class: "badge bg-red-500")
    elsif bet.failed?
      content_tag(:span, "Failed", class: "badge bg-gray-500")
    else
      content_tag(:span, bet.result.to_s.humanize, class: "badge bg-blue-500")
    end
  end

  # Format bet amount
  def format_bet_amount(amount)
    number_to_currency(amount, precision: 2)
  end

  # Display transaction hash in a readable format
  def format_transaction_hash(hash)
    return "N/A" unless hash.present?

    # Truncate the hash for display
    "#{hash[0..5]}...#{hash[-6..-1]}"
  end

  # Generate a link to verify the transaction on chain
  def transaction_verification_link(bet)
    return "Not yet confirmed" unless bet.confirmed_on_chain?

    # In MVP, this would link to a page explaining the verification process
    # In Phase 2, this would link to the actual blockchain explorer
    link_to "Verify on Chain", "#",
      class: "text-blue-500 underline",
      data: {
        controller: "tooltip",
        tooltip_content: "Transaction: #{bet.signed_transaction_payload}"
      }
  end

  # Display the odds at the time of betting
  def display_bet_odds(bet)
    win_probability = bet.lottery.odds_json["win_probability"].to_f
    "#{(win_probability * 100).round(2)}%"
  end

  # Display potential payout for a bet
  def potential_payout(bet)
    case bet.lottery.payout_strategy
    when "fixed_multiplier"
      multiplier = 2.0
    when "progressive"
      multiplier = 1.5
    when "jackpot"
      multiplier = 10.0
    else
      multiplier = 2.0
    end

    potential_amount = bet.amount * multiplier
    number_to_currency(potential_amount, precision: 2)
  end
end
