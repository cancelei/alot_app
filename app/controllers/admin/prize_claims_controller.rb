class Admin::PrizeClaimsController < Admin::BaseController
  before_action :set_prize_claim, only: [ :show, :edit, :update, :process_claim, :expire_claim ]

  def index
    @filter_status = params[:status] || "all"
    @search_query = params[:search]

    @prize_claims = PrizeClaim.includes(:user, :ticket, :draw, :lottery_game)
                             .order(created_at: :desc)

    # Apply status filter
    case @filter_status
    when "pending"
      @prize_claims = @prize_claims.pending
    when "auto_credited"
      @prize_claims = @prize_claims.auto_credited
    when "manual_claim_required"
      @prize_claims = @prize_claims.manual_claim_required
    when "claimed"
      @prize_claims = @prize_claims.claimed
    when "expired"
      @prize_claims = @prize_claims.expired
    when "expiring_soon"
      @prize_claims = @prize_claims.expiring_soon
    end

    # Apply search filter
    if @search_query.present?
      @prize_claims = @prize_claims.joins(:user)
                                  .where("users.email ILIKE ? OR users.username ILIKE ?",
                                        "%#{@search_query}%", "%#{@search_query}%")
    end

    @prize_claims = @prize_claims.limit(50)

    # Statistics for dashboard cards
    @stats = calculate_prize_claim_stats
  end

  def show
    @claim_history = @prize_claim.ticket.payments.order(created_at: :desc)
  end

  def edit
    # Allow editing of processing notes and status for manual claims
  end

  def update
    if @prize_claim.update(prize_claim_params)
      redirect_to admin_prize_claim_path(@prize_claim),
                  notice: "Prize claim updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def process_claim
    if @prize_claim.manual_claim_required?
      if @prize_claim.manual_claim_complete!(current_user)
        redirect_to admin_prize_claim_path(@prize_claim),
                    notice: "Prize claim processed successfully. Funds credited to user account."
      else
        redirect_to admin_prize_claim_path(@prize_claim),
                    alert: "Failed to process prize claim. Please try again."
      end
    else
      redirect_to admin_prize_claim_path(@prize_claim),
                  alert: "This claim cannot be manually processed."
    end
  end

  def expire_claim
    if @prize_claim.expire_claim!
      redirect_to admin_prize_claim_path(@prize_claim),
                  notice: "Prize claim has been expired."
    else
      redirect_to admin_prize_claim_path(@prize_claim),
                  alert: "Failed to expire prize claim."
    end
  end

  def bulk_process
    case params[:bulk_action]
    when "process_auto_credits"
      processed_count = PrizeClaim.auto_credit_eligible_prizes
      redirect_to admin_prize_claims_path,
                  notice: "Processed #{processed_count} auto-credit eligible prizes."
    when "expire_old_claims"
      expired_count = PrizeClaim.expire_old_claims
      redirect_to admin_prize_claims_path,
                  notice: "Expired #{expired_count} old claims."
    when "process_pending"
      PrizeClaim.process_pending_claims
      redirect_to admin_prize_claims_path,
                  notice: "Processing all pending claims in background."
    else
      redirect_to admin_prize_claims_path, alert: "Invalid bulk action."
    end
  end

  private

  def set_prize_claim
    @prize_claim = PrizeClaim.find(params[:id])
  end

  def prize_claim_params
    params.require(:prize_claim).permit(:processing_notes, :status)
  end

  def calculate_prize_claim_stats
    {
      total_claims: PrizeClaim.count,
      pending_claims: PrizeClaim.pending.count,
      auto_credited: PrizeClaim.auto_credited.count,
      manual_required: PrizeClaim.manual_claim_required.count,
      claimed_total: PrizeClaim.claimed.count,
      expired_total: PrizeClaim.expired.count,
      expiring_soon: PrizeClaim.expiring_soon.count,
      total_prize_amount: PrizeClaim.sum(:prize_amount) || 0,
      total_tax_withheld: PrizeClaim.sum(:tax_withholding_amount) || 0,
      pending_prize_value: PrizeClaim.where(status: [ "pending", "manual_claim_required" ]).sum(:prize_amount) || 0
    }
  end
end
