# Helper methods for lottery views
module LotteriesHelper
  # Returns a formatted status badge for a lottery
  # @param lottery [Lottery] the lottery object
  # @return [String] HTML for the status badge
  def lottery_status_badge(lottery)
    status_class = lottery.active? ? "bg-green-100 text-green-800" : "bg-gray-100 text-gray-800"
    content_tag(:span, lottery.status.humanize,
      class: "px-3 py-1 rounded-full text-sm font-medium #{status_class}")
  end

  # Returns a formatted bet status badge
  # @param bet [Bet] the bet object
  # @return [String] HTML for the bet status badge
  def bet_status_badge(bet)
    if !bet.confirmed_on_chain?
      status = "pending"
      status_class = "bg-yellow-100 text-yellow-800"
    elsif bet.won?
      status = "won"
      status_class = "bg-green-100 text-green-800"
    elsif bet.lost?
      status = "lost"
      status_class = "bg-red-100 text-red-800"
    elsif bet.paid_out?
      status = "paid out"
      status_class = "bg-blue-100 text-blue-800"
    else
      status = "confirmed"
      status_class = "bg-gray-100 text-gray-800"
    end

    content_tag(:span, status.humanize,
      class: "px-2 py-1 rounded-full text-xs font-medium #{status_class}")
  end

  # Returns a formatted lottery card for the lottery list
  # @param lottery [Lottery] the lottery object
  # @param options [Hash] options for the card
  # @option options [Boolean] :featured whether this is a featured lottery
  # @return [String] HTML for the lottery card
  def lottery_card_classes(options = {})
    if options[:featured]
      "bg-gradient-to-r from-blue-500 to-indigo-600 text-white"
    else
      "bg-white text-gray-800"
    end
  end

  # Format lottery duration
  # @param lottery [Lottery] the lottery object
  # @return [String] formatted duration text
  def format_lottery_duration(lottery)
    if lottery.is_endless
      "Endless"
    else
      pluralize(lottery.cycles_count, "cycle")
    end
  end

  # Format lottery odds as a percentage
  # @param lottery [Lottery] the lottery object
  # @return [String] formatted odds percentage
  def format_win_probability(lottery)
    return "0%" unless lottery.odds_json && lottery.odds_json["win_probability"]

    number_to_percentage(lottery.odds_json["win_probability"].to_f * 100, precision: 1)
  end
end
