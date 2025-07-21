require "test_helper"

class DrawnNumbersControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get drawn_numbers_create_url
    assert_response :success
  end
end
