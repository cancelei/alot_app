class Admin::FeatureRequestsController < ApplicationController
  before_action :require_admin
  before_action :set_feature_request, only: [ :show, :update, :change_status ]

  def index
    @feature_requests = policy_scope(FeatureRequest).order(created_at: :desc)

    # Filter by status if provided
    if params[:status].present? && FeatureRequest.statuses.keys.include?(params[:status])
      @feature_requests = @feature_requests.where(status: params[:status])
    end

    # Filter by category if provided
    if params[:category].present? && FeatureRequest.categories.keys.include?(params[:category])
      @feature_requests = @feature_requests.where(category: params[:category])

      # Filter by game_type for lottery games
      if params[:category] == "lottery_game" && params[:game_type].present?
        @feature_requests = @feature_requests.where("title ILIKE ? OR description ILIKE ?", "%#{params[:game_type]}%", "%#{params[:game_type]}%")
      end
    end
  end

  def show
    authorize @feature_request
  end

  def update
    authorize @feature_request

    if @feature_request.update(feature_request_params)
      redirect_to admin_feature_request_path(@feature_request), notice: "Feature request was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def change_status
    authorize @feature_request

    if @feature_request.update(status: params[:status])
      redirect_to admin_feature_request_path(@feature_request), notice: "Feature request status was successfully updated."
    else
      redirect_to admin_feature_request_path(@feature_request), alert: "Failed to update feature request status."
    end
  end

  private

  def set_feature_request
    @feature_request = FeatureRequest.find(params[:id])
  end

  def feature_request_params
    params.require(:feature_request).permit(:title, :description, :status, :category)
  end
end
