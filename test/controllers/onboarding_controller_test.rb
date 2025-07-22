require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get onboarding_index_url
    assert_response :success
  end

  test "should get age_verification" do
    get onboarding_age_verification_url
    assert_response :success
  end

  test "should get location_verification" do
    get onboarding_location_verification_url
    assert_response :success
  end

  test "should get identity_verification" do
    get onboarding_identity_verification_url
    assert_response :success
  end

  test "should get tutorial" do
    get onboarding_tutorial_url
    assert_response :success
  end

  test "should get complete" do
    get onboarding_complete_url
    assert_response :success
  end
end
