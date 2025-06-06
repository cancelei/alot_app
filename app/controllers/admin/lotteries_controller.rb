class Admin::LotteriesController < ApplicationController
  before_action :require_admin
  before_action :set_lottery, only: [ :show, :edit, :update, :destroy, :publish, :deploy_contract ]

  def index
    @lotteries = policy_scope(Lottery)

    # Filter by status if provided
    if params[:status].present? && Lottery.statuses.key?(params[:status])
      @lotteries = @lotteries.where(status: params[:status])
    end

    @lotteries = @lotteries.order(created_at: :desc)
  end

  def show
    authorize @lottery
  end

  def new
    @lottery = Lottery.new
    authorize @lottery
  end

  def create
    @lottery = Lottery.new(lottery_params)
    @lottery.created_by = current_user
    authorize @lottery

    if @lottery.save
      redirect_to admin_lottery_path(@lottery), notice: "Lottery was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @lottery
  end

  def update
    authorize @lottery

    if @lottery.update(lottery_params)
      redirect_to admin_lottery_path(@lottery), notice: "Lottery was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @lottery

    @lottery.destroy
    redirect_to admin_lotteries_path, notice: "Lottery was successfully destroyed."
  end

  def publish
    authorize @lottery

    if @lottery.update(status: :active)
      redirect_to admin_lottery_path(@lottery), notice: "Lottery was successfully published."
    else
      redirect_to admin_lottery_path(@lottery), alert: "Failed to publish lottery."
    end
  end

  def deploy_contract
    authorize @lottery

    # Use LotteryDeploymentService to deploy lottery to blockchain
    deployment_service = LotteryDeploymentService.new(@lottery)
    result = deployment_service.deploy

    if result[:success]
      # Generate verification data for transparency
      verification_data = deployment_service.generate_verification_data

      # Store verification data for later reference
      @lottery.update(verification_data: verification_data)

      redirect_to admin_lottery_path(@lottery), notice: "Smart contract deployed successfully."
    else
      redirect_to admin_lottery_path(@lottery), alert: "Failed to deploy smart contract: #{result[:error]}"
    end
  end

  private

  def set_lottery
    @lottery = Lottery.find(params[:id])
  end

  def lottery_params
    lottery_attributes = params.require(:lottery).permit(
      :name,
      :description,
      :cycles_count,
      :reinvestment_ratio,
      :is_endless,
      :payout_strategy,
      :visibility,
      :current_payout,
      :max_numbers_to_draw,
      :cost_per_number
    )

    # Handle odds_json separately to ensure it's properly formatted as a hash
    if params[:lottery][:odds_json].present?
      odds_data = params[:lottery][:odds_json].to_unsafe_h

      # Convert win_probability from percentage to decimal (e.g., 50% -> 0.5)
      if odds_data["win_probability"].present?
        # Ensure it's a float and convert from percentage to decimal
        win_prob = odds_data["win_probability"].to_f / 100.0
        # Ensure it doesn't exceed 0.99 (99%)
        win_prob = [ win_prob, 0.99 ].min
        odds_data["win_probability"] = win_prob
      end

      lottery_attributes[:odds_json] = odds_data
    else
      # Provide default odds if none specified
      lottery_attributes[:odds_json] = {
        "win_probability" => 0.1,  # 10%
        "payout_multiplier" => 2.0,
        "min_bet" => 1.0
      }
    end

    lottery_attributes
  end
end
