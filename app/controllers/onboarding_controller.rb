class OnboardingController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  before_action :redirect_if_onboarding_complete, except: [ :complete ]
  before_action :set_current_step

  def index
    # Landing page for new users
    if user_signed_in?
      redirect_to_current_step
    end
  end

  def age_verification
    if request.post?
      if params[:date_of_birth].present?
        current_user.update!(date_of_birth: Date.parse(params[:date_of_birth]))

        if current_user.age_verified?
          redirect_to onboarding_location_verification_path
        else
          flash[:alert] = "You must be 18 or older to use this service."
          render :age_verification
        end
      else
        flash[:alert] = "Please enter your date of birth."
        render :age_verification
      end
    end
  rescue Date::Error
    flash[:alert] = "Please enter a valid date."
    render :age_verification
  end

  def location_verification
    if request.post?
      # In a real implementation, this would use IP geolocation or GPS
      # For now, we'll simulate location verification
      location_allowed = params[:location_confirmed] == "true"

      if location_allowed
        current_user.update!(location_verified: true)
        redirect_to onboarding_identity_verification_path
      else
        flash[:alert] = "This service is not available in your location."
        render :location_verification
      end
    end
  end

  def identity_verification
    if request.post?
      # In a real implementation, this would integrate with identity verification service
      # For now, we'll simulate identity verification based on form completion
      if params[:full_name].present? && params[:phone_number].present?
        # Assign a default state jurisdiction (in production, this would be based on user's location)
        default_state = StateJurisdiction.where(lottery_legal: true, is_active: true).first

        current_user.update!(
          name: params[:full_name],
          phone_number: params[:phone_number],
          identity_verified: true,
          state_jurisdiction: default_state
        )
        redirect_to onboarding_tutorial_path
      else
        flash[:alert] = "Please complete all required fields."
        render :identity_verification
      end
    end
  end

  def tutorial
    if request.post?
      # Ensure user has a username (required for onboarding completion)
      if current_user.username.blank?
        # Generate a default username based on their name or email
        base_username = current_user.name&.downcase&.gsub(/[^a-z0-9]/, "") || current_user.email.split("@").first
        username = base_username
        counter = 1

        # Ensure username is unique
        while User.exists?(username: username)
          username = "#{base_username}#{counter}"
          counter += 1
        end

        current_user.update!(username: username)
      end

      # Mark tutorial as completed and redirect to dashboard
      redirect_to onboarding_complete_path
    end
  end

  def complete
    # Reload user to ensure we have the latest data
    current_user.reload

    if current_user.onboarding_complete?
      # Give new user a welcome bonus
      if current_user.account_balance == 0
        current_user.add_funds!(10.00)
        flash[:notice] = "Welcome to the lottery! You've received a $10 welcome bonus."
      else
        flash[:notice] = "Welcome back to the lottery!"
      end

      redirect_to dashboard_path
    else
      # Debug what's missing
      Rails.logger.info "Onboarding incomplete for user #{current_user.id}:"
      Rails.logger.info "- Age verified: #{current_user.age_verified?}"
      Rails.logger.info "- Location verified: #{current_user.location_verified?}"
      Rails.logger.info "- Identity verified: #{current_user.identity_verified?}"
      Rails.logger.info "- State jurisdiction: #{current_user.state_jurisdiction.present?}"
      Rails.logger.info "- Name: #{current_user.name.present?}"
      Rails.logger.info "- Username: #{current_user.username.present?}"

      redirect_to_current_step
    end
  end

  private

  def redirect_if_onboarding_complete
    if current_user&.onboarding_complete?
      redirect_to dashboard_path
    end
  end

  def set_current_step
    return unless current_user

    @current_step = if !current_user.age_verified?
      :age_verification
    elsif !current_user.location_verified?
      :location_verification
    elsif !current_user.identity_verified?
      :identity_verification
    elsif current_user.onboarding_complete?
      :complete
    else
      :tutorial
    end
  end

  def redirect_to_current_step
    case @current_step
    when :age_verification
      redirect_to onboarding_age_verification_path
    when :location_verification
      redirect_to onboarding_location_verification_path
    when :identity_verification
      redirect_to onboarding_identity_verification_path
    when :tutorial
      redirect_to onboarding_tutorial_path
    when :complete
      redirect_to onboarding_complete_path
    end
  end

  def dashboard_path
    dashboard_index_path
  end
end
