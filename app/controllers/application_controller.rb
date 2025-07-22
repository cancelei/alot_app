class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern  # Temporarily disabled for testing

  # include Pundit::Authorization  # Temporarily disabled for testing

  # Authenticate user for all actions by default
  # before_action :authenticate_user!  # Temporarily disabled for testing

  # Pundit authorization error handling
  # rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized  # Temporarily disabled

  # Add flash messages for Turbo
  # before_action :set_flash_for_turbo  # Temporarily disabled for testing

  protected

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referer || root_path)
  end

  def set_flash_for_turbo
    # Make flash messages work with Turbo
    flash.now[:notice] = flash[:notice] if flash[:notice]
    flash.now[:alert] = flash[:alert] if flash[:alert]
  end

  # Check if user is a super admin
  def require_admin
    unless current_user&.super_admin?
      flash[:alert] = "You must be an admin to access this section."
      redirect_to root_path
    end
  end
end
