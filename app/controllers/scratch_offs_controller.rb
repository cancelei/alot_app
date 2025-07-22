class ScratchOffsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_onboarding_complete
  before_action :set_scratch_off, only: [ :show, :scratch, :claim ]

  def index
    @scratch_offs = current_user.scratch_offs.includes(:instant_game).recent
    @total_spent = @scratch_offs.sum { |s| s.instant_game.ticket_price }
    @total_won = @scratch_offs.where.not(prize_amount: nil).sum(:prize_amount)
    @winning_tickets = @scratch_offs.where("prize_amount > 0").count
    @total_tickets = @scratch_offs.count
  end

  def show
    # Ensure this scratch-off belongs to the current user
    unless @scratch_off.user == current_user
      redirect_to scratch_offs_path, alert: "You can only view your own tickets."
      return
    end

    @instant_game = @scratch_off.instant_game
    @can_scratch = @scratch_off.status == "unscratched"
    @is_winner = @scratch_off.prize_amount && @scratch_off.prize_amount > 0
  end

  def scratch
    unless @scratch_off.user == current_user
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    unless @scratch_off.status == "unscratched"
      render json: { error: "This ticket has already been scratched" }, status: :unprocessable_entity
      return
    end

    begin
      # Perform the scratch action
      result = @scratch_off.scratch!

      if result
        # Update user's account balance if they won
        if @scratch_off.prize_amount && @scratch_off.prize_amount > 0
          current_user.update!(
            account_balance: current_user.account_balance + @scratch_off.prize_amount
          )
        end

        render json: {
          success: true,
          prize_amount: @scratch_off.prize_amount || 0,
          winning_symbols: @scratch_off.winning_symbols || [],
          is_winner: @scratch_off.prize_amount && @scratch_off.prize_amount > 0,
          message: @scratch_off.prize_amount && @scratch_off.prize_amount > 0 ?
                   "Congratulations! You won $#{number_with_delimiter(@scratch_off.prize_amount.to_i)}!" :
                   "Better luck next time!"
        }
      else
        render json: { error: "Unable to scratch ticket" }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Scratch-off error: #{e.message}"
      render json: { error: "An error occurred while scratching" }, status: :internal_server_error
    end
  end

  def claim
    unless @scratch_off.user == current_user
      redirect_to @scratch_off, alert: "Unauthorized access."
      return
    end

    unless @scratch_off.status == "scratched" && @scratch_off.prize_amount && @scratch_off.prize_amount > 0
      redirect_to @scratch_off, alert: "This ticket cannot be claimed."
      return
    end

    begin
      if @scratch_off.claim_prize!
        redirect_to @scratch_off, notice: "Prize claimed successfully! $#{number_with_delimiter(@scratch_off.prize_amount.to_i)} has been added to your account."
      else
        redirect_to @scratch_off, alert: "Unable to claim prize. Please contact support."
      end
    rescue StandardError => e
      Rails.logger.error "Prize claim error: #{e.message}"
      redirect_to @scratch_off, alert: "An error occurred while claiming your prize."
    end
  end

  private

  def set_scratch_off
    @scratch_off = ScratchOff.find(params[:id])
  end

  def ensure_onboarding_complete
    unless current_user.fully_verified?
      redirect_to onboarding_path, alert: "Please complete your account verification to access your tickets."
    end
  end
end
