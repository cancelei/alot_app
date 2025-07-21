class FeatureRequest < ApplicationRecord
  belongs_to :submitted_by, class_name: "User"

  # Enums
  enum "status", { under_review: 0, approved: 1, rejected: 2, shipped: 3 }
  enum "category", { general: 0, lottery_game: 1, user_interface: 2, payment: 3 }, prefix: true

  # Validations
  validates :title, presence: true
  validates :description, presence: true

  # Scopes
  scope :pending_review, -> { where(status: :under_review) }
  scope :approved_requests, -> { where(status: :approved) }
  scope :rejected_requests, -> { where(status: :rejected) }
  scope :shipped_features, -> { where(status: :shipped) }

  # Category scopes
  scope :lottery_games, -> { where(category: :lottery_game) }

  # Callbacks
  before_validation :set_default_values

  private

  def set_default_values
    self.status ||= :under_review
    self.category ||= :general
  end
end
