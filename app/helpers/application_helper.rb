module ApplicationHelper
  # Returns the appropriate Tailwind CSS classes for a feature request status
  def status_color(status)
    case status.to_sym
    when :under_review
      "bg-yellow-100 text-yellow-800"
    when :approved
      "bg-blue-100 text-blue-800"
    when :rejected
      "bg-red-100 text-red-800"
    when :shipped
      "bg-green-100 text-green-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
