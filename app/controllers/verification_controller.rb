class VerificationController < ApplicationController
  # Public controller - no authentication required for transparency

  # Show verification page for a lottery result
  def lottery_result
    @lottery = Lottery.find_by(id: params[:lottery_id])
    @result = LotteryResult.find_by(lottery_id: params[:lottery_id], cycle_number: params[:cycle_number])

    unless @lottery && @result
      flash[:alert] = "Lottery result not found"
      redirect_to root_path and return
    end

    # Get verification steps for the result
    @verification_steps = @result.verification_steps

    # Get winning bets for this lottery cycle
    @winning_bets = Bet.where(
      lottery_id: @lottery.id,
      cycle_number: @result.cycle_number,
      result: :won,
      confirmed_on_chain: true
    ).includes(:user, :payout_log)
  end

  # Show verification page for a bet
  def bet
    @bet = Bet.find_by(id: params[:id])

    unless @bet
      flash[:alert] = "Bet not found"
      redirect_to root_path and return
    end

    @lottery = @bet.lottery
    @result = LotteryResult.find_by(lottery_id: @lottery.id, cycle_number: @bet.cycle_number)

    # Get verification steps for the bet
    @verification_steps = bet_verification_steps

    # Get payout information if the bet was won and paid out
    @payout = PayoutLog.find_by(bet_id: @bet.id) if @bet.paid_out?
  end

  # Show verification page for a payout
  def payout
    @payout = PayoutLog.find_by(id: params[:id])

    unless @payout
      flash[:alert] = "Payout not found"
      redirect_to root_path and return
    end

    @bet = @payout.bet
    @lottery = @payout.lottery
    @result = LotteryResult.find_by(lottery_id: @lottery.id, cycle_number: @bet.cycle_number)

    # Get verification steps for the payout
    @verification_steps = payout_verification_steps
  end

  private

  # Generate verification steps for a bet
  def bet_verification_steps
    [
      {
        step: 1,
        title: "Bet Information",
        description: "Verify the bet details",
        data: {
          bet_id: @bet.id,
          player: @bet.user.username || @bet.user.email,
          amount: @bet.amount,
          chosen_numbers: @bet.chosen_numbers,
          created_at: @bet.created_at
        }
      },
      {
        step: 2,
        title: "Lottery Information",
        description: "Verify the lottery details",
        data: {
          lottery_id: @lottery.id,
          lottery_name: @lottery.name,
          cycle_number: @bet.cycle_number
        }
      },
      {
        step: 3,
        title: "Blockchain Confirmation",
        description: "Verify the bet was confirmed on the blockchain",
        data: {
          confirmed_on_chain: @bet.confirmed_on_chain?,
          confirmation_hash: @bet.confirmation_hash,
          confirmed_at: @bet.confirmed_at
        }
      },
      {
        step: 4,
        title: "Result Verification",
        description: "Verify the bet result",
        data: {
          result: @bet.result,
          winning_number: @result&.winning_number || "Not available",
          result_determined_at: @bet.updated_at
        }
      }
    ]
  end

  # Generate verification steps for a payout
  def payout_verification_steps
    [
      {
        step: 1,
        title: "Payout Information",
        description: "Verify the payout details",
        data: {
          payout_id: @payout.id,
          amount: @payout.amount,
          player: @payout.player.username || @payout.player.email,
          created_at: @payout.created_at
        }
      },
      {
        step: 2,
        title: "Bet Information",
        description: "Verify the winning bet details",
        data: {
          bet_id: @bet.id,
          amount: @bet.amount,
          chosen_numbers: @bet.chosen_numbers,
          result: @bet.result
        }
      },
      {
        step: 3,
        title: "Lottery Information",
        description: "Verify the lottery details",
        data: {
          lottery_id: @lottery.id,
          lottery_name: @lottery.name,
          cycle_number: @bet.cycle_number,
          winning_number: @result&.winning_number || "Not available"
        }
      },
      {
        step: 4,
        title: "Blockchain Transaction",
        description: "Verify the payout transaction on the blockchain",
        data: {
          transaction_hash: @payout.transaction_hash,
          transaction_timestamp: @payout.updated_at
        }
      }
    ]
  end
end
