class Admin::PayoutsController < ApplicationController
  before_action :require_admin
  before_action :set_bet, only: [ :process_payout, :show ]

  def index
    @payouts = PayoutLog.includes(:user, :bet, :lottery).order(created_at: :desc).page(params[:page]).per(20)

    # Filter by status if provided
    if params[:status].present?
      @payouts = @payouts.where(status: params[:status])
    end

    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      @payouts = @payouts.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    # Calculate totals
    @total_payouts = @payouts.count
    @total_amount = @payouts.sum(:amount)
  end

  def show
    @payout = PayoutLog.find_by(bet: @bet)

    if @payout.nil?
      redirect_to admin_bet_path(@bet), alert: "No payout found for this bet."
    end
  end

  def pending
    @pending_bets = Bet.includes(:user, :lottery)
                        .where(result: :won, confirmed_on_chain: true, paid_out: false)
                        .order(created_at: :desc)
                        .page(params[:page]).per(20)

    # Calculate potential payout amounts
    @pending_bets.each do |bet|
      payout_service = PayoutProcessingService.new(bet)
      bet.potential_payout = payout_service.calculate_potential_payout
    end

    # Calculate totals
    @total_pending = @pending_bets.count
    @total_pending_amount = @pending_bets.sum { |bet| bet.potential_payout.to_f }
  end

  def process_payout
    authorize @bet, :process_payout?

    # Only allow processing payouts for winning bets
    unless @bet.won? && @bet.confirmed_on_chain?
      redirect_to admin_bet_path(@bet), alert: "This bet is not eligible for payout."
      return
    end

    # Process payout using PayoutProcessingService
    payout_service = PayoutProcessingService.new(@bet)
    result = payout_service.process_payout

    if result[:success]
      redirect_to admin_bet_path(@bet), notice: "Payout processed successfully."
    else
      redirect_to admin_bet_path(@bet), alert: "Failed to process payout: #{result[:error]}"
    end
  end

  def process_all_pending
    authorize Bet, :process_payouts?

    # Get all pending winning bets
    pending_bets = Bet.where(result: :won, confirmed_on_chain: true, paid_out: false)

    # Process each payout
    success_count = 0
    error_messages = []

    pending_bets.each do |bet|
      payout_service = PayoutProcessingService.new(bet)
      result = payout_service.process_payout

      if result[:success]
        success_count += 1
      else
        error_messages << "Bet ##{bet.id}: #{result[:error]}"
      end
    end

    # Redirect with appropriate message
    if error_messages.any?
      redirect_to pending_admin_payouts_path, alert: "Processed #{success_count} payouts with #{error_messages.size} errors: #{error_messages.join(', ')}"
    else
      redirect_to pending_admin_payouts_path, notice: "Successfully processed #{success_count} payouts."
    end
  end

  private

  def set_bet
    @bet = Bet.find(params[:id])
  end
end
