class Admin::LotteryGamesController < ApplicationController
  before_action :require_admin
  before_action :set_lottery_game, only: [ :show, :edit, :update, :destroy, :activate, :pause, :schedule_draw, :configure_cycles, :start_cycles, :complete_cycles ]

  def index
    @lottery_games = LotteryGame.includes(:state_jurisdiction, :created_by)
                                .order(created_at: :desc)
                                .page(params[:page])

    # Filter by status if provided
    @lottery_games = @lottery_games.where(status: params[:status]) if params[:status].present?

    # Filter by game type if provided
    @lottery_games = @lottery_games.where(game_type: params[:game_type]) if params[:game_type].present?

    # Filter by state if provided
    @lottery_games = @lottery_games.joins(:state_jurisdiction)
                                  .where(state_jurisdictions: { state_code: params[:state] }) if params[:state].present?

    @game_stats = {
      total: LotteryGame.count,
      active: LotteryGame.active_games.count,
      draft: LotteryGame.where(status: :draft).count,
      paused: LotteryGame.where(status: :paused).count
    }
  end

  def show
    @recent_draws = @lottery_game.draws.includes(:tickets).order(draw_date: :desc).limit(10)
    @recent_tickets = @lottery_game.tickets.includes(:user).order(purchase_date: :desc).limit(20)
    @game_stats = {
      total_tickets_sold: @lottery_game.total_tickets_sold,
      total_revenue: @lottery_game.tickets.sum(:cost),
      platform_revenue: @lottery_game.platform_revenue,
      current_prize_pool: @lottery_game.current_prize_pool,
      next_draw: @lottery_game.next_draw_time,
      win_frequency: @lottery_game.win_frequency
    }
  end

  def new
    @lottery_game = LotteryGame.new
    @state_jurisdictions = StateJurisdiction.active.lottery_legal
    set_form_options
  end

  def create
    @lottery_game = LotteryGame.new(lottery_game_params)
    @lottery_game.created_by = current_user

    if @lottery_game.save
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game was successfully created."
    else
      @state_jurisdictions = StateJurisdiction.active.lottery_legal
      set_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @state_jurisdictions = StateJurisdiction.active.lottery_legal
    set_form_options
  end

  def update
    if @lottery_game.update(lottery_game_params)
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game was successfully updated."
    else
      @state_jurisdictions = StateJurisdiction.active.lottery_legal
      set_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @lottery_game.tickets.exists?
      redirect_to admin_lottery_games_path,
                  alert: "Cannot delete lottery game with existing tickets."
    else
      @lottery_game.destroy
      redirect_to admin_lottery_games_path,
                  notice: "Lottery game was successfully deleted."
    end
  end

  def activate
    if @lottery_game.draft? || @lottery_game.paused?
      @lottery_game.update!(status: :active)
      @lottery_game.schedule_next_draw!
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game has been activated."
    else
      redirect_to admin_lottery_game_path(@lottery_game),
                  alert: "Cannot activate this lottery game."
    end
  end

  def pause
    if @lottery_game.active?
      @lottery_game.update!(status: :paused)
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game has been paused."
    else
      redirect_to admin_lottery_game_path(@lottery_game),
                  alert: "Cannot pause this lottery game."
    end
  end

  def schedule_draw
    if @lottery_game.active?
      @lottery_game.schedule_next_draw!
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Next draw has been scheduled."
    else
      redirect_to admin_lottery_game_path(@lottery_game),
                  alert: "Game must be active to schedule draws."
    end
  end

  # Quick creation methods for different game types
  def create_rapid_game
    @lottery_game = LotteryGame.create_rapid_game(rapid_game_params)
    @lottery_game.created_by = current_user

    if @lottery_game.save
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Rapid lottery game was successfully created."
    else
      redirect_to new_admin_lottery_game_path,
                  alert: "Failed to create rapid game: " + @lottery_game.errors.full_messages.join(", ")
    end
  end

  def create_hourly_game
    @lottery_game = LotteryGame.create_hourly_game(hourly_game_params)
    @lottery_game.created_by = current_user

    if @lottery_game.save
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Hourly lottery game was successfully created."
    else
      redirect_to new_admin_lottery_game_path,
                  alert: "Failed to create hourly game: " + @lottery_game.errors.full_messages.join(", ")
    end
  end

  def create_daily_game
    @lottery_game = LotteryGame.create_daily_game(daily_game_params)
    @lottery_game.created_by = current_user

    if @lottery_game.save
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Daily lottery game was successfully created."
    else
      redirect_to new_admin_lottery_game_path,
                  alert: "Failed to create daily game: " + @lottery_game.errors.full_messages.join(", ")
    end
  end

  def create_weekly_game
    @lottery_game = LotteryGame.create_weekly_game(weekly_game_params)
    @lottery_game.created_by = current_user

    if @lottery_game.save
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Weekly lottery game was successfully created."
    else
      redirect_to new_admin_lottery_game_path,
                  alert: "Failed to create weekly game: " + @lottery_game.errors.full_messages.join(", ")
    end
  end

  # Cycle Management Actions
  def configure_cycles
    # Show cycle configuration form
  end

  def start_cycles
    if @lottery_game.cycle_status.blank? || @lottery_game.cycle_status == "completed"
      @lottery_game.start_cycles!
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game cycles have been started."
    else
      redirect_to admin_lottery_game_path(@lottery_game),
                  alert: "Cannot start cycles - game already has active cycles."
    end
  end

  def complete_cycles
    if @lottery_game.cycle_status == "active" && @lottery_game.cycles_completed?
      @lottery_game.complete_cycles!
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game cycles have been completed and payouts processed."
    elsif @lottery_game.cycle_status == "pending_admin_review"
      # Allow manual completion for admin discretion cases
      @lottery_game.complete_cycles!
      redirect_to admin_lottery_game_path(@lottery_game),
                  notice: "Lottery game cycles manually completed."
    else
      redirect_to admin_lottery_game_path(@lottery_game),
                  alert: "Cannot complete cycles at this time."
    end
  end

  private

  def set_lottery_game
    @lottery_game = LotteryGame.find(params[:id])
  end

  def lottery_game_params
    params.require(:lottery_game).permit(
      :state_jurisdiction_id, :name, :description, :status, :game_type,
      :ticket_price, :draw_frequency_minutes, :base_prize_pool,
      :contribution_rate, :platform_fee_rate, :number_range_min,
      :number_range_max, :numbers_to_select, :winner_selection,
      :first_place_percentage, :second_place_percentage, :third_place_percentage,
      :pool_reset_rule, :win_reduction_percentage, :prize_cap,
      :max_players_per_draw, :allows_ticket_sales, :allows_quick_pick,
      :allows_multi_draw, :max_multi_draw_count, :official_api_endpoint,
      :official_game_id, :requires_official_integration,
      # Cycle management parameters
      :cycle_length_minutes, :total_cycles, :payout_strategy
    )
  end

  def rapid_game_params
    params.require(:rapid_game).permit(
      :state_jurisdiction_id, :name, :description, :ticket_price,
      :draw_frequency_minutes, :base_prize_pool, :contribution_rate,
      :platform_fee_rate, :number_range_min, :number_range_max,
      :numbers_to_select, :max_players_per_draw
    )
  end

  def hourly_game_params
    params.require(:hourly_game).permit(
      :state_jurisdiction_id, :name, :description, :ticket_price,
      :base_prize_pool, :contribution_rate, :platform_fee_rate,
      :number_range_min, :number_range_max, :numbers_to_select,
      :winner_selection, :pool_reset_rule
    )
  end

  def daily_game_params
    params.require(:daily_game).permit(
      :state_jurisdiction_id, :name, :description, :ticket_price,
      :base_prize_pool, :contribution_rate, :platform_fee_rate,
      :number_range_min, :number_range_max, :numbers_to_select,
      :winner_selection, :pool_reset_rule, :prize_cap
    )
  end

  def weekly_game_params
    params.require(:weekly_game).permit(
      :state_jurisdiction_id, :name, :description, :ticket_price,
      :base_prize_pool, :contribution_rate, :platform_fee_rate,
      :number_range_min, :number_range_max, :numbers_to_select,
      :winner_selection, :pool_reset_rule, :prize_cap,
      :first_place_percentage, :second_place_percentage, :third_place_percentage
    )
  end

  def set_form_options
    @game_types = LotteryGame.game_types.keys.map { |key| [ key.humanize, key ] }
    @winner_selections = LotteryGame.winner_selections.keys.map { |key| [ key.humanize, key ] }
    @pool_reset_rules = LotteryGame.pool_reset_rules.keys.map { |key| [ key.humanize, key ] }
    @draw_frequency_options = [
      [ "1 Minute", 1 ],
      [ "5 Minutes", 5 ],
      [ "15 Minutes", 15 ],
      [ "30 Minutes", 30 ],
      [ "1 Hour", 60 ],
      [ "6 Hours", 360 ],
      [ "12 Hours", 720 ],
      [ "24 Hours (Daily)", 1440 ],
      [ "7 Days (Weekly)", 10080 ]
    ]
  end
end
