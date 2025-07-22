class PrizeClaimsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_prize_claim, only: [ :show, :claim ]

  def index
    @prize_claims = current_user.prize_claims
                                .includes(:ticket, :draw, :lottery_game)
                                .order(created_at: :desc)

    # Filter by status if requested
    if params[:status].present?
      @prize_claims = @prize_claims.where(status: params[:status])
    end

    # Statistics for dashboard
    @stats = {
      total_winnings: @prize_claims.sum(:prize_amount) || 0,
      pending_claims: @prize_claims.pending.count,
      auto_credited: @prize_claims.auto_credited.count,
      manual_required: @prize_claims.manual_claim_required.count,
      total_claimed: @prize_claims.claimed.count + @prize_claims.auto_credited.count,
      expiring_soon: @prize_claims.expiring_soon.count
    }
  end

  def show
    # Additional context for the view
    @winning_numbers = @prize_claim.draw.winning_numbers_array
    @user_numbers = @prize_claim.ticket.numbers_array
    @matches = (@winning_numbers & @user_numbers).length
  end

  def claim
    unless @prize_claim.can_claim_prize?
      redirect_to prize_claims_path, alert: "This prize cannot be claimed at this time."
      return
    end

    if @prize_claim.can_auto_credit?
      if @prize_claim.auto_credit_prize!
        redirect_to prize_claim_path(@prize_claim),
                    notice: "Congratulations! Your prize of $#{number_with_delimiter(@prize_claim.net_prize_amount)} has been credited to your account."
      else
        redirect_to prize_claim_path(@prize_claim),
                    alert: "There was an error processing your prize claim. Please contact support."
      end
    else
      # Require manual claim process
      if @prize_claim.require_manual_claim!
        redirect_to prize_claim_path(@prize_claim),
                    notice: "Your prize claim has been submitted for manual processing. You will be notified when it's ready."
      else
        redirect_to prize_claim_path(@prize_claim),
                    alert: "There was an error submitting your prize claim. Please contact support."
      end
    end
  end

  private

  def set_prize_claim
    @prize_claim = current_user.prize_claims.find(params[:id])
  end
end
