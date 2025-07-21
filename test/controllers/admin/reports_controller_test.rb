require "test_helper"

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get players" do
    get admin_reports_players_url
    assert_response :success
  end

  test "should get bets" do
    get admin_reports_bets_url
    assert_response :success
  end

  test "should get payouts" do
    get admin_reports_payouts_url
    assert_response :success
  end
end
