module AuthenticationHelpers
  def sign_in_admin(admin_user = nil)
    admin_user ||= create(:user, :admin)
    sign_in admin_user
    admin_user
  end

  def sign_in_user(user = nil)
    user ||= create(:user)
    sign_in user
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :controller
  config.include AuthenticationHelpers, type: :feature
end
