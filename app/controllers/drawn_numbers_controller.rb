class DrawnNumbersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bet
  before_action :check_lottery_active
  before_action :check_max_numbers

  def create
    @drawn_number = @bet.drawn_numbers.new(drawn_number_params)
    @drawn_number.user = current_user
    @drawn_number.lottery = @bet.lottery

    authorize @drawn_number

    respond_to do |format|
      if @drawn_number.save
        # Calculate the additional cost for this number
        additional_cost = @bet.lottery.cost_per_number

        # Update the bet amount to include the cost of this number draw
        new_amount = @bet.amount + additional_cost
        @bet.update(amount: new_amount)

        format.html { redirect_to lottery_path(@bet.lottery), notice: "Number #{@drawn_number.number} was successfully drawn." }
        format.json { render json: @drawn_number, status: :created }
        format.turbo_stream
      else
        format.html { redirect_to lottery_path(@bet.lottery), alert: "Failed to draw number: #{@drawn_number.errors.full_messages.join(', ')}" }
        format.json { render json: @drawn_number.errors, status: :unprocessable_entity }
        format.turbo_stream
      end
    end
  end

  private

  def set_bet
    @bet = Bet.find(params[:bet_id])
  end

  def drawn_number_params
    params.require(:drawn_number).permit(:number)
  end


  def check_lottery_active
    unless @bet.lottery.active?
      redirect_to lottery_path(@bet.lottery), alert: "This lottery is not active. You cannot draw numbers."
    end
  end

  def check_max_numbers
    current_drawn_count = @bet.drawn_numbers.count
    max_allowed = @bet.lottery.max_numbers_to_draw

    if current_drawn_count >= max_allowed
      redirect_to lottery_path(@bet.lottery), alert: "You have already drawn the maximum number of numbers (#{max_allowed}) for this bet."
    end
  end
end
