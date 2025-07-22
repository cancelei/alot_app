class Admin::InstantGamesController < ApplicationController
  before_action :require_admin
  before_action :set_instant_game, only: [ :show, :edit, :update, :destroy, :activate, :pause, :add_tickets ]

  def index
    @instant_games = InstantGame.includes(:state_jurisdiction, :created_by)
                                .order(created_at: :desc)
                                .page(params[:page])

    # Filter by status if provided
    @instant_games = @instant_games.where(status: params[:status]) if params[:status].present?

    # Filter by price point if provided
    @instant_games = @instant_games.where(price_point: params[:price_point]) if params[:price_point].present?

    # Filter by state if provided
    @instant_games = @instant_games.joins(:state_jurisdiction)
                                  .where(state_jurisdictions: { state_code: params[:state] }) if params[:state].present?

    @game_stats = {
      total: InstantGame.count,
      active: InstantGame.active_games.count,
      draft: InstantGame.where(status: :draft).count,
      sold_out: InstantGame.where(status: :sold_out).count
    }

    @price_points = InstantGame.distinct.pluck(:price_point).sort
  end

  def show
    @recent_purchases = @instant_game.scratch_offs.includes(:user).order(purchase_date: :desc).limit(20)
    @recent_winners = @instant_game.scratch_offs.winning_tickets.includes(:user).order(updated_at: :desc).limit(10)
    @game_stats = {
      tickets_sold: @instant_game.tickets_sold,
      tickets_remaining: @instant_game.tickets_remaining,
      total_revenue: @instant_game.tickets_sold * @instant_game.price_point,
      total_prizes_paid: @instant_game.scratch_offs.winning_tickets.sum(:prize_won),
      top_prizes_remaining: @instant_game.top_prizes_remaining,
      overall_win_rate: @instant_game.overall_win_rate,
      expected_payout: @instant_game.expected_payout_percentage
    }
  end

  def new
    @instant_game = InstantGame.new
    @state_jurisdictions = StateJurisdiction.active.lottery_legal
    set_form_options
  end

  def create
    @instant_game = InstantGame.new(instant_game_params)
    @instant_game.created_by = current_user
    @instant_game.tickets_remaining = @instant_game.total_tickets

    if @instant_game.save
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "Instant game was successfully created."
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
    if @instant_game.update(instant_game_params)
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "Instant game was successfully updated."
    else
      @state_jurisdictions = StateJurisdiction.active.lottery_legal
      set_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @instant_game.scratch_offs.exists?
      redirect_to admin_instant_games_path,
                  alert: "Cannot delete instant game with existing tickets."
    else
      @instant_game.destroy
      redirect_to admin_instant_games_path,
                  notice: "Instant game was successfully deleted."
    end
  end

  def activate
    if @instant_game.draft? || @instant_game.paused?
      @instant_game.update!(status: :active, launch_date: Time.current)
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "Instant game has been activated and is now available for purchase."
    else
      redirect_to admin_instant_game_path(@instant_game),
                  alert: "Cannot activate this instant game."
    end
  end

  def pause
    if @instant_game.active?
      @instant_game.update!(status: :paused)
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "Instant game has been paused."
    else
      redirect_to admin_instant_game_path(@instant_game),
                  alert: "Cannot pause this instant game."
    end
  end

  def add_tickets
    additional_tickets = params[:additional_tickets].to_i

    if additional_tickets > 0
      @instant_game.add_tickets!(additional_tickets)
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "Added #{additional_tickets} tickets to the game."
    else
      redirect_to admin_instant_game_path(@instant_game),
                  alert: "Please specify a valid number of tickets to add."
    end
  end

  # Quick creation methods for different price points
  def create_dollar_game
    @instant_game = InstantGame.create_dollar_game(dollar_game_params)
    @instant_game.created_by = current_user

    if @instant_game.save
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "$1 instant game was successfully created."
    else
      redirect_to new_admin_instant_game_path,
                  alert: "Failed to create $1 game: " + @instant_game.errors.full_messages.join(", ")
    end
  end

  def create_five_dollar_game
    @instant_game = InstantGame.create_five_dollar_game(five_dollar_game_params)
    @instant_game.created_by = current_user

    if @instant_game.save
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "$5 instant game was successfully created."
    else
      redirect_to new_admin_instant_game_path,
                  alert: "Failed to create $5 game: " + @instant_game.errors.full_messages.join(", ")
    end
  end

  def create_ten_dollar_game
    @instant_game = InstantGame.create_ten_dollar_game(ten_dollar_game_params)
    @instant_game.created_by = current_user

    if @instant_game.save
      redirect_to admin_instant_game_path(@instant_game),
                  notice: "$10 instant game was successfully created."
    else
      redirect_to new_admin_instant_game_path,
                  alert: "Failed to create $10 game: " + @instant_game.errors.full_messages.join(", ")
    end
  end

  def prize_structure_builder
    # AJAX endpoint for building prize structures dynamically
    price_point = params[:price_point].to_f
    total_tickets = params[:total_tickets].to_i

    suggested_structure = generate_prize_structure(price_point, total_tickets)

    render json: { prize_structure: suggested_structure }
  end

  private

  def set_instant_game
    @instant_game = InstantGame.find(params[:id])
  end

  def instant_game_params
    params.require(:instant_game).permit(
      :state_jurisdiction_id, :name, :description, :status, :price_point,
      :total_tickets, :top_prize_amount, :overall_odds, :theme,
      :game_instructions, :ticket_design_url, :second_chance_promotion,
      :second_chance_eligible, :launch_date, :end_date,
      prize_structure: {}
    )
  end

  def dollar_game_params
    params.require(:dollar_game).permit(
      :state_jurisdiction_id, :name, :description, :total_tickets,
      :top_prize_amount, :theme, :game_instructions
    )
  end

  def five_dollar_game_params
    params.require(:five_dollar_game).permit(
      :state_jurisdiction_id, :name, :description, :total_tickets,
      :top_prize_amount, :theme, :game_instructions, :second_chance_eligible
    )
  end

  def ten_dollar_game_params
    params.require(:ten_dollar_game).permit(
      :state_jurisdiction_id, :name, :description, :total_tickets,
      :top_prize_amount, :theme, :game_instructions, :second_chance_eligible
    )
  end

  def set_form_options
    @themes = [
      "Classic", "Holiday", "Sports", "Adventure", "Mystery",
      "Treasure Hunt", "Lucky Numbers", "Crossword", "Bingo", "Slots"
    ]

    @price_point_options = [
      [ "$1", 1.00 ],
      [ "$2", 2.00 ],
      [ "$3", 3.00 ],
      [ "$5", 5.00 ],
      [ "$10", 10.00 ],
      [ "$20", 20.00 ],
      [ "$25", 25.00 ],
      [ "$30", 30.00 ],
      [ "$50", 50.00 ]
    ]
  end

  def generate_prize_structure(price_point, total_tickets)
    # Generate a balanced prize structure based on price point and ticket count
    case price_point
    when 1.0
      {
        "1.00" => { "quantity" => (total_tickets * 0.1).to_i },
        "2.00" => { "quantity" => (total_tickets * 0.05).to_i },
        "5.00" => { "quantity" => (total_tickets * 0.02).to_i },
        "10.00" => { "quantity" => (total_tickets * 0.01).to_i },
        "25.00" => { "quantity" => (total_tickets * 0.004).to_i },
        "100.00" => { "quantity" => (total_tickets * 0.001).to_i }
      }
    when 5.0
      {
        "5.00" => { "quantity" => (total_tickets * 0.2).to_i },
        "10.00" => { "quantity" => (total_tickets * 0.1).to_i },
        "25.00" => { "quantity" => (total_tickets * 0.04).to_i },
        "50.00" => { "quantity" => (total_tickets * 0.02).to_i },
        "100.00" => { "quantity" => (total_tickets * 0.01).to_i },
        "1000.00" => { "quantity" => (total_tickets * 0.002).to_i }
      }
    when 10.0
      {
        "10.00" => { "quantity" => (total_tickets * 0.3).to_i },
        "20.00" => { "quantity" => (total_tickets * 0.15).to_i },
        "50.00" => { "quantity" => (total_tickets * 0.06).to_i },
        "100.00" => { "quantity" => (total_tickets * 0.03).to_i },
        "500.00" => { "quantity" => (total_tickets * 0.006).to_i },
        "5000.00" => { "quantity" => (total_tickets * 0.001).to_i }
      }
    else
      # Default structure for other price points
      {
        "#{price_point}" => { "quantity" => (total_tickets * 0.1).to_i },
        "#{price_point * 2}" => { "quantity" => (total_tickets * 0.05).to_i },
        "#{price_point * 5}" => { "quantity" => (total_tickets * 0.02).to_i },
        "#{price_point * 10}" => { "quantity" => (total_tickets * 0.01).to_i }
      }
    end
  end
end
