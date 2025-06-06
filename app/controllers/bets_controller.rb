class BetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bet, only: [ :show ]

  def create
    @lottery = Lottery.find(params[:lottery_id])
    @bet = @lottery.bets.new(bet_params)
    @bet.player = current_user
    @bet.cycle_number = 1 # Default to cycle 1 for now

    authorize @bet

    # Generate transaction payload BEFORE saving to satisfy validation
    blockchain_service = BlockchainTransactionService.new(@bet)
    transaction_payload = blockchain_service.generate_transaction_payload
    signed_transaction = blockchain_service.sign_transaction(transaction_payload)
    @bet.signed_transaction_payload = signed_transaction

    if @bet.save
      # Schedule background job to simulate blockchain confirmation
      BetConfirmationJob.set(wait: 5.seconds).perform_later(@bet.id)

      redirect_to @bet, notice: "Bet placed successfully! Waiting for blockchain confirmation."
    else
      Rails.logger.error("Failed to save bet: #{@bet.errors.full_messages.join(', ')}")
      flash.now[:alert] = "Failed to place bet: #{@bet.errors.full_messages.join(', ')}"
      render "lotteries/show", status: :unprocessable_entity
    end
  end

  def show
    authorize @bet
  end

  private

  def set_bet
    @bet = Bet.find(params[:id])
  end

  def bet_params
    params.require(:bet).permit(:amount)
  end

  # These methods have been replaced by BlockchainTransactionService
end
