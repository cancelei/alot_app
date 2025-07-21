module LotteryStatusHelper
  # Render a lottery status badge with appropriate styling
  def render_lottery_status_badge(lottery)
    case lottery.status
    when "draft"
      content_tag(:span, "Draft", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800")
    when "active"
      content_tag(:span, "Active", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800")
    when "paused"
      content_tag(:span, "Paused", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800")
    when "ended"
      content_tag(:span, "Ended", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800")
    when "deployed"
      content_tag(:span, "Deployed", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800")
    else
      content_tag(:span, lottery.status.to_s.titleize, class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800")
    end
  end

  # Render a bet status badge with appropriate styling
  def render_bet_status_badge(bet)
    if bet.paid_out?
      content_tag(:span, "Paid Out", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800")
    elsif bet.won? && bet.confirmed_on_chain?
      content_tag(:span, "Won", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800")
    elsif bet.lost? && bet.confirmed_on_chain?
      content_tag(:span, "Lost", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800")
    elsif bet.confirmed_on_chain?
      content_tag(:span, "Confirmed", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800")
    elsif bet.pending?
      content_tag(:span, "Pending", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800")
    else
      content_tag(:span, "Processing", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800")
    end
  end

  # Render a feature request status badge with appropriate styling
  def render_feature_request_status_badge(feature_request)
    case feature_request.status
    when "pending"
      content_tag(:span, "Pending", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-yellow-100 text-yellow-800")
    when "approved"
      content_tag(:span, "Approved", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800")
    when "rejected"
      content_tag(:span, "Rejected", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800")
    when "shipped"
      content_tag(:span, "Shipped", class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800")
    else
      content_tag(:span, feature_request.status.to_s.titleize, class: "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800")
    end
  end

  # Render admin feature request action buttons based on status
  def render_admin_feature_request_actions(feature_request)
    case feature_request.status
    when "pending"
      safe_join([
        button_to(approve_admin_feature_request_path(feature_request), method: :patch, class: "text-blue-600 hover:text-blue-900 mr-2") do
          "Approve"
        end,
        button_to(reject_admin_feature_request_path(feature_request), method: :patch, class: "text-red-600 hover:text-red-900") do
          "Reject"
        end
      ])
    when "approved"
      button_to(ship_admin_feature_request_path(feature_request), method: :patch, class: "text-green-600 hover:text-green-900") do
        "Mark as Shipped"
      end
    else
      # No actions for rejected or shipped feature requests
      ""
    end
  end
end
