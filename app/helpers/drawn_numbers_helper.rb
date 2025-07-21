module DrawnNumbersHelper
  # Calculate the total cost of drawn numbers for a bet
  def total_drawn_numbers_cost(bet)
    bet.drawn_numbers.count * bet.lottery.cost_per_number
  end

  # Calculate the remaining number of draws available
  def remaining_draws(bet)
    bet.lottery.max_numbers_to_draw - bet.drawn_numbers.count
  end

  # Calculate the potential maximum additional cost for remaining draws
  def potential_additional_cost(bet)
    remaining_draws(bet) * bet.lottery.cost_per_number
  end
end
