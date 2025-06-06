require "test_helper"

class FeatureRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get feature_requests_new_url
    assert_response :success
  end

  test "should get create" do
    get feature_requests_create_url
    assert_response :success
  end

  test "should get index" do
    get feature_requests_index_url
    assert_response :success
  end
end
