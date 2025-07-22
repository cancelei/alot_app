class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_user, only: [ :show, :edit, :update, :activate, :deactivate, :verify_identity, :reject_identity, :update_role, :update_limits ]

  def index
    @users = User.includes(:identity_verification, :state_jurisdiction)
                 .order(created_at: :desc)
                 .limit(50)

    # Filter by role
    if params[:role].present?
      @users = params[:role] == "super_admin" ? @users.super_admin : @users.player
    end

    # Filter by verification status if specified
    if params[:verified].present?
      if params[:verified] == "true"
        @users = @users.where(identity_verified: true)
      else
        @users = @users.where(identity_verified: false)
      end
    end

    # Filter by state if specified
    @users = @users.where(state_jurisdiction_id: params[:state_id]) if params[:state_id].present?

    # Search by name or email
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where("name ILIKE ? OR email ILIKE ?", search_term, search_term)
    end

    # Statistics for the view
    @total_users = User.count
    @verified_users = User.joins(:identity_verification).where(identity_verifications: { status: "verified" }).count
    @admin_users = User.super_admin.count
    @self_excluded_users = User.where(self_excluded: true).count
    @states = StateJurisdiction.active.order(:state_name)
  end

  def show
    @user_tickets = @user.tickets.includes(:lottery_game).order(created_at: :desc).limit(10)
    @user_scratch_offs = @user.scratch_offs.includes(:instant_game).order(created_at: :desc).limit(10)
    @user_subscriptions = @user.subscriptions.includes(:lottery_game).order(created_at: :desc).limit(5)
    @identity_verification = @user.identity_verification

    # Calculate user statistics
    @total_spent = (@user.tickets.joins(:lottery_game).sum("lottery_games.ticket_price") || 0) +
                   (@user.scratch_offs.joins(:instant_game).sum("instant_games.ticket_price") || 0)
    @total_won = (@user.tickets.winning_tickets.sum(:prize_amount) || 0) +
                 (@user.scratch_offs.winning_tickets.sum(:prize_amount) || 0)
    @net_result = @total_won - @total_spent
  end

  def edit
    # Edit form for user details
  end

  def update
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "User updated successfully."
    else
      render :edit, alert: "Failed to update user."
    end
  end

  def activate
    if @user.update(self_excluded: false, self_exclusion_date: nil)
      redirect_to admin_user_path(@user), notice: "User account activated successfully."
    else
      redirect_to admin_user_path(@user), alert: "Failed to activate user account."
    end
  end

  def deactivate
    if @user.update(self_excluded: true, self_exclusion_date: Time.current)
      redirect_to admin_user_path(@user), notice: "User account deactivated successfully."
    else
      redirect_to admin_user_path(@user), alert: "Failed to deactivate user account."
    end
  end

  def verify_identity
    if @user.identity_verification&.update(status: :verified, verification_date: Time.current)
      @user.update(identity_verified: true)
      redirect_to admin_user_path(@user), notice: "User identity verified successfully."
    else
      redirect_to admin_user_path(@user), alert: "Failed to verify user identity."
    end
  end

  def reject_identity
    if @user.identity_verification&.update(status: :rejected, verification_date: nil)
      @user.update(identity_verified: false)
      redirect_to admin_user_path(@user), notice: "User identity verification rejected."
    else
      redirect_to admin_user_path(@user), alert: "Failed to reject identity verification."
    end
  end

  def update_role
    if @user.update(role: params[:role])
      redirect_to admin_user_path(@user), notice: "User role updated successfully."
    else
      redirect_to admin_user_path(@user), alert: "Failed to update user role."
    end
  end

  def update_limits
    limit_params = params.require(:user).permit(:spending_limit_daily, :spending_limit_weekly, :spending_limit_monthly)

    if @user.update(limit_params)
      redirect_to admin_user_path(@user), notice: "Spending limits updated successfully."
    else
      redirect_to admin_user_path(@user), alert: "Failed to update spending limits."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def ensure_admin
    redirect_to root_path unless current_user&.super_admin?
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :phone_number, :date_of_birth,
      :spending_limit_daily, :spending_limit_weekly, :spending_limit_monthly,
      :state_jurisdiction_id, :location_verified, :identity_verified
    )
  end
end
