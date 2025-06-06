class FeatureRequestsController < ApplicationController
  before_action :set_feature_request, only: [ :show ]

  def new
    @feature_request = FeatureRequest.new
    authorize @feature_request
  end

  def create
    @feature_request = FeatureRequest.new(feature_request_params)
    @feature_request.submitted_by = current_user
    @feature_request.status = :pending_review # Default status

    authorize @feature_request

    if @feature_request.save
      redirect_to feature_requests_path, notice: "Feature request was successfully submitted."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @feature_requests = policy_scope(FeatureRequest).order(created_at: :desc)
  end

  def show
    authorize @feature_request
  end

  private

  def set_feature_request
    @feature_request = FeatureRequest.find(params[:id])
  end

  def feature_request_params
    params.require(:feature_request).permit(:title, :description)
  end
end
