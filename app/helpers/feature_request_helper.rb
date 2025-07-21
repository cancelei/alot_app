module FeatureRequestHelper
  # Format feature request status with appropriate color badge
  def feature_request_status_badge(feature_request)
    case feature_request.status
    when "pending_review"
      content_tag(:span, "Pending Review", class: "badge bg-yellow-500")
    when "approved"
      content_tag(:span, "Approved", class: "badge bg-green-500")
    when "rejected"
      content_tag(:span, "Rejected", class: "badge bg-red-500")
    when "in_progress"
      content_tag(:span, "In Progress", class: "badge bg-blue-500")
    when "shipped"
      content_tag(:span, "Shipped", class: "badge bg-purple-500")
    else
      content_tag(:span, feature_request.status.to_s.humanize, class: "badge bg-gray-500")
    end
  end

  # Format the time since the feature request was created
  def time_since_submission(feature_request)
    time_ago_in_words(feature_request.created_at) + " ago"
  end

  # Display voting buttons for feature requests
  # In MVP, this is just a UI element without functionality
  # In Phase 2, this would be implemented with actual voting
  def feature_request_voting_buttons(feature_request)
    content_tag(:div, class: "flex items-center space-x-2") do
      concat(button_tag(class: "text-gray-500 hover:text-green-500", data: { action: "click->feature-request#upvote" }) do
        content_tag(:i, nil, class: "fas fa-thumbs-up")
      end)
      concat(content_tag(:span, "0", class: "text-sm font-medium", data: { target: "feature-request.voteCount" }))
      concat(button_tag(class: "text-gray-500 hover:text-red-500", data: { action: "click->feature-request#downvote" }) do
        content_tag(:i, nil, class: "fas fa-thumbs-down")
      end)
    end
  end

  # Display admin actions for feature requests
  def feature_request_admin_actions(feature_request)
    return unless current_user&.super_admin?

    content_tag(:div, class: "flex items-center space-x-2") do
      statuses = FeatureRequest.statuses.keys - [ feature_request.status ]

      statuses.each do |status|
        concat(button_to(
          status.humanize,
          change_status_admin_feature_request_path(feature_request, status: status),
          method: :patch,
          class: "btn btn-sm btn-outline-primary",
          data: { turbo_confirm: "Are you sure you want to change the status to #{status.humanize}?" }
        ))
      end
    end
  end
end
