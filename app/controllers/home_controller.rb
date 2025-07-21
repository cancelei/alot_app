class HomeController < ApplicationController
  # Skip authentication for the landing page
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    # Get the jackpot lottery (lottery with highest current payout)
    @jackpot_lottery = Lottery.active_lotteries.order(current_payout: :desc).first

    # Get recent active lotteries
    @recent_lotteries = Lottery.active_lotteries.order(created_at: :desc).limit(3)
  end
end
