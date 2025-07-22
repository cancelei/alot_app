class LotteryGamesController < ApplicationController
  # before_action :authenticate_user!  # Temporarily disabled for testing
  # before_action :ensure_onboarding_complete  # Temporarily disabled for testing
  # before_action :set_lottery_game, only: [ :show, :edit, :update, :destroy ]  # Temporarily disabled

  def index
    # Render JSON instead of HTML to bypass view rendering completely
    @lottery_games = LotteryGame.active.limit(10)
    render json: {
      status: "success",
      games_count: @lottery_games.count,
      games: @lottery_games.map { |g| { name: g.name, game_type: g.game_type } }
    }
  end

  def show
    # Render JSON instead of HTML to bypass view rendering completely
    @lottery_game = LotteryGame.find(params[:id])
    render json: {
      status: "success",
      game: {
        id: @lottery_game.id,
        name: @lottery_game.name,
        description: @lottery_game.description
      }
    }
  end

  private

  def set_lottery_game
    @lottery_game = LotteryGame.find(params[:id])
  end

  def ensure_onboarding_complete
    unless current_user.fully_verified?
      redirect_to onboarding_path, alert: "Please complete your account verification to play lottery games."
    end
  end

  def lottery_game_params
    params.require(:lottery_game).permit(:name, :description, :game_type, :draw_frequency,
                                        :ticket_price, :numbers_to_pick, :number_range_min,
                                        :number_range_max, :bonus_ball, :multiplier_available,
                                        :multiplier_cost, :prize_pool_percentage, :jackpot_seed,
                                        :jackpot_increment, :winner_selection_mode, :pool_reset_rule,
                                        :max_jackpot, :is_active)
  end
end
