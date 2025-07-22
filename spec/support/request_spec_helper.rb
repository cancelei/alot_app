module RequestSpecHelper
  def sign_in_as_admin
    admin_user = create(:user, :admin)
    post user_session_path, params: {
      user: {
        email: admin_user.email,
        password: admin_user.password
      }
    }
    admin_user
  end

  def sign_in_as_user(user = nil)
    user ||= create(:user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: user.password
      }
    }
    user
  end
end

RSpec.configure do |config|
  config.include RequestSpecHelper, type: :request
end
