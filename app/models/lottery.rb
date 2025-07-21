class Lottery < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  # Associations
  has_many :bets, dependent: :nullify
  has_many :drawn_numbers, dependent: :destroy
  has_many :payout_logs, dependent: :nullify

  # Enums
  enum "status", { draft: 0, active: 1, ended: 2 }
  enum "payout_strategy", { pool: 0, owner: 1, split_payout: 2 }
  enum "visibility", { private_lottery: 0, public_lottery: 1 }

  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :cycles_count, numericality: { greater_than: 0 }, if: -> { !is_endless }
  validates :reinvestment_ratio, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :odds_json, presence: true
  validates :max_numbers_to_draw, numericality: { greater_than: 0, only_integer: true }
  validates :cost_per_number, numericality: { greater_than: 0 }
  validate :validate_odds_json

  # Scopes
  scope :active_lotteries, -> { where(status: :active, visibility: :public_lottery) }
  scope :jackpot_lottery, -> { active_lotteries.order(current_payout: :desc).first }

  # Calculate the end date for the lottery
  # For endless lotteries, returns a date 24 hours from now
  # For non-endless lotteries, returns the estimated end date based on deployment time and cycles
  def end_date
    if is_endless
      # For endless lotteries, just return 24 hours from now (next cycle)
      Time.current + 24.hours
    else
      # For non-endless lotteries with a deployment time, calculate based on cycles
      # Each cycle is assumed to be 24 hours
      return nil unless deployed_at
      deployed_at + (24.hours * cycles_count)
    end
  end

  # Calculate the next draw time for the lottery
  # For active lotteries, this is based on the most recent draw or deployment time
  # Returns a time 24 hours after the last draw or deployment time
  def next_draw_at
    return nil unless active? && deployed_at

    # Get the most recent drawn number's timestamp, if any
    last_draw = drawn_numbers.order(created_at: :desc).first

    if last_draw
      # Next draw is 24 hours after the last draw
      last_draw.created_at + 24.hours
    else
      # If no draws yet, next draw is 24 hours after deployment
      deployed_at + 24.hours
    end
  end

  # Callbacks
  before_save :set_default_values

  private

  def set_default_values
    self.status ||= :draft
    self.visibility ||= :private_lottery
    self.payout_strategy ||= :pool
  end

  def validate_odds_json
    return if odds_json.blank?

    # Ensure odds_json is a valid JSON object
    unless odds_json.is_a?(Hash)
      errors.add(:odds_json, "must be a valid JSON object")
      return
    end

    # Validate that win probability is not unreasonably high
    if odds_json["win_probability"].present? && odds_json["win_probability"].to_f > 0.99
      errors.add(:odds_json, "win probability cannot exceed 99%")
    end

    # Validate that payout percentage is reasonable
    if odds_json["payout_percentage"].present? && odds_json["payout_percentage"].to_f <= 0
      errors.add(:odds_json, "payout percentage must be greater than 0%")
    end
  end
end
