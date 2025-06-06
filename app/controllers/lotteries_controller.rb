class LotteriesController < ApplicationController
  # Allow visitors to see lotteries without logging in
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_lottery, only: [ :show ]

  # GET /lotteries
  # Lists all available public lotteries
  def index
    @lotteries = fetch_public_lotteries
    @jackpot_lottery = find_jackpot_lottery
  end

  # GET /lotteries/:id
  # Shows details for a specific lottery
  def show
    authorize @lottery
    load_user_bets_and_form if user_signed_in?
  end

  private

  # Finds the lottery by ID
  def set_lottery
    @lottery = Lottery.find(params[:id])
  end

  # Fetches all active public lotteries ordered by payout
  def fetch_public_lotteries
    policy_scope(Lottery)
      .active
      .where(visibility: :public_lottery)
      .order(current_payout: :desc)
  end

  # Returns the lottery with the highest current payout
  def find_jackpot_lottery
    @lotteries.first
  end

  # Loads user-specific data for the lottery page
  def load_user_bets_and_form
    @bets = current_user.bets
                        .where(lottery: @lottery)
                        .order(created_at: :desc)
    @bet = Bet.new(lottery: @lottery)
  end
end
