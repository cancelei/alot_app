class FeatureRequest < ApplicationRecord
  belongs_to :submitted_by, class_name: "User"

  # Enums
  enum "status", { under_review: 0, approved: 1, rejected: 2, shipped: 3 }

  # Validations
  validates :title, presence: true
  validates :description, presence: true

  # Scopes
  scope :pending_review, -> { where(status: :under_review) }
  scope :approved_requests, -> { where(status: :approved) }
  scope :rejected_requests, -> { where(status: :rejected) }
  scope :shipped_features, -> { where(status: :shipped) }

  # Callbacks
  before_validation :set_default_status

  private

  def set_default_status
    self.status ||= :under_review
  end
end
