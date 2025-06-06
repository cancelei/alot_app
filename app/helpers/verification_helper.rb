module VerificationHelper
  # Format transaction hash for display
  def format_transaction_hash(hash)
    return "N/A" unless hash.present?

    # Show first 10 and last 10 characters with ellipsis in between
    "#{hash[0..9]}...#{hash[-10..-1]}"
  end

  # Format verification step with appropriate styling
  def verification_step(step, value, description)
    content_tag(:div, class: "verification-step mb-4 border-b pb-3") do
      concat(content_tag(:h4, step, class: "text-lg font-semibold text-gray-700"))
      concat(content_tag(:div, value, class: "text-xl font-mono bg-gray-100 p-2 rounded my-2 break-all"))
      concat(content_tag(:p, description, class: "text-sm text-gray-600"))
    end
  end

  # Create a verification badge for display
  def verification_badge(verified = true)
    if verified
      content_tag(:span, class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800") do
        concat(content_tag(:svg, class: "w-4 h-4 mr-1.5", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, nil, fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z", clip_rule: "evenodd")
        end)
        concat("Verified")
      end
    else
      content_tag(:span, class: "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800") do
        concat(content_tag(:svg, class: "w-4 h-4 mr-1.5", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, nil, fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z", clip_rule: "evenodd")
        end)
        concat("Unverified")
      end
    end
  end

  # Display verification timestamp
  def verification_timestamp(time)
    return "Not yet verified" unless time.present?

    content_tag(:div, class: "text-sm text-gray-500") do
      concat(content_tag(:span, "Verified at: ", class: "font-medium"))
      concat(time.strftime("%B %d, %Y %H:%M:%S %Z"))
    end
  end

  # Generate a link to a blockchain explorer (simulated in MVP)
  def blockchain_explorer_link(address)
    return "N/A" unless address.present?

    # In MVP, this would link to a page explaining the verification process
    # In Phase 2, this would link to the actual blockchain explorer
    link_to address, "#", class: "text-blue-500 underline", data: {
      controller: "tooltip",
      tooltip_content: "This would link to a blockchain explorer in Phase 2",
      tooltip_position: "top"
    }
  end

  # Display odds verification
  def odds_verification(odds_json)
    return "N/A" unless odds_json.present?

    win_probability = odds_json["win_probability"].to_f

    content_tag(:div, class: "flex items-center") do
      concat(content_tag(:span, "#{(win_probability * 100).round(2)}%", class: "font-semibold mr-2"))
      concat(content_tag(:span, class: "text-xs bg-gray-200 rounded-full px-2 py-1") do
        "1 in #{(1 / win_probability).round(2)}"
      end)
    end
  end
end
