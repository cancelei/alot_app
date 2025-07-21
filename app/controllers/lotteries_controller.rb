class LotteriesController < ApplicationController
  # Allow visitors to see lotteries without logging in
  skip_before_action :authenticate_user!, only: [ :index, :show, :feature_requests ]
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

  # GET /lotteries/feature_requests
  # Shows feature request form for lottery games
  def feature_requests
    @lottery_game_requests = FeatureRequest.lottery_games.order(created_at: :desc).limit(5)
    @feature_request = FeatureRequest.new
  end

  def game_type
    # Get the game type from the params
    @game_type = params[:type]

    # Validate that the game type is one of the allowed types
    valid_types = [ "scratch_card", "powerball", "keno", "daily_draw" ]

    unless valid_types.include?(@game_type)
      flash[:alert] = "Invalid game type requested"
      redirect_to feature_requests_lotteries_path and return
    end

    # Initialize a new feature request with lottery_game category and prefilled title
    game_title = @game_type.titleize
    @feature_request = FeatureRequest.new(
      category: :lottery_game,
      title: "#{game_title} Game Request"
    )

    # Render the appropriate template
    render "game_types/#{@game_type}"
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
