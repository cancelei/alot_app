class VerificationsController < ApplicationController
  # Skip authentication for public verification
  skip_before_action :authenticate_user!, only: [ :verify_bet, :verify_lottery ]

  def verify_bet
    @bet = Bet.find(params[:id])

    # Generate verification data using BlockchainTransactionService
    blockchain_service = BlockchainTransactionService.new(@bet)
    @verification_data = blockchain_service.generate_verification_data

    # For MVP, we'll display the verification data
    # In Phase 2, this would link to actual blockchain explorer

    respond_to do |format|
      format.html
      format.json { render json: @verification_data }
    end
  end

  def verify_lottery
    @lottery = Lottery.find(params[:id])

    # Only deployed lotteries can be verified
    unless @lottery.smart_contract_address.present?
      redirect_to lottery_path(@lottery), alert: "This lottery has not been deployed to the blockchain yet."
      return
    end

    # Generate verification data using LotteryDeploymentService
    deployment_service = LotteryDeploymentService.new(@lottery)
    @verification_data = deployment_service.generate_verification_data

    # For MVP, we'll display the verification data
    # In Phase 2, this would link to actual blockchain explorer

    respond_to do |format|
      format.html
      format.json { render json: @verification_data }
    end
  end

  def verify_result
    @bet = Bet.find(params[:id])

    # Only confirmed bets can have their results verified
    unless @bet.confirmed_on_chain?
      redirect_to bet_path(@bet), alert: "This bet has not been confirmed on the blockchain yet."
      return
    end

    # Use LotteryResultService to demonstrate the result calculation
    result_service = LotteryResultService.new(@bet)

    # Create a step-by-step verification process for transparency
    @verification_steps = [
      {
        step: "Transaction Hash",
        value: @bet.signed_transaction_payload,
        description: "The unique identifier for this bet transaction on the blockchain."
      },
      {
        step: "Random Seed Generation",
        value: @bet.signed_transaction_payload.sub(/^0x/, "")[0..7].to_i(16),
        description: "A deterministic seed derived from the transaction hash."
      },
      {
        step: "Win Probability",
        value: "#{(@bet.lottery.odds_json['win_probability'].to_f * 100).round(2)}%",
        description: "The probability of winning as defined by the lottery."
      },
      {
        step: "Result Calculation",
        value: @bet.result,
        description: "The result determined by comparing the random value to the win probability."
      }
    ]

    respond_to do |format|
      format.html
      format.json { render json: @verification_steps }
    end
  end
end
