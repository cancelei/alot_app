require "test_helper"

class Admin::LotteriesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_lotteries_index_url
    assert_response :success
  end

  test "should get new" do
    get admin_lotteries_new_url
    assert_response :success
  end

  test "should get create" do
    get admin_lotteries_create_url
    assert_response :success
  end

  test "should get edit" do
    get admin_lotteries_edit_url
    assert_response :success
  end

  test "should get update" do
    get admin_lotteries_update_url
    assert_response :success
  end

  test "should get destroy" do
    get admin_lotteries_destroy_url
    assert_response :success
  end
end
