class Lottery < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  # Associations
  has_many :bets, dependent: :nullify
  has_many :drawn_numbers, dependent: :destroy
  has_many :payout_logs, dependent: :nullify

  # New associations for redesigned lottery system
  has_many :draws, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

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

    # Get the most recent draw, if any
    last_draw = draws.order(draw_date: :desc).first

    if last_draw
      # Next draw is based on lottery frequency (default 24 hours)
      last_draw.draw_date + draw_frequency.hours
    else
      # If no draws yet, next draw is 24 hours after deployment
      deployed_at + 24.hours
    end
  end

  # New methods for redesigned lottery system
  def ticket_cost
    cost_per_number * numbers_to_draw
  end

  def numbers_to_draw
    max_numbers_to_draw
  end

  def max_number
    odds_json&.dig("max_number") || 49 # Default to 49 like most lotteries
  end

  def min_matches_to_win
    odds_json&.dig("min_matches_to_win") || 3
  end

  def draw_frequency
    odds_json&.dig("draw_frequency_hours") || 24
  end

  def prize_multiplier_for_matches(matches)
    multipliers = odds_json&.dig("prize_multipliers") || {
      "3" => 2,
      "4" => 10,
      "5" => 100,
      "6" => 1000
    }
    multipliers[matches.to_s]&.to_f || 1.0
  end

  def next_draw
    draws.upcoming.order(:draw_date).first
  end

  def latest_draw
    draws.completed.order(draw_date: :desc).first
  end

  def create_next_draw
    next_date = next_draw_at || 24.hours.from_now

    draws.create!(
      draw_date: next_date,
      jackpot_amount: calculate_next_jackpot,
      status: :scheduled
    )
  end

  def total_tickets_sold
    tickets.count
  end

  def total_revenue
    tickets.sum(:cost) || 0
  end

  def total_prizes_paid
    tickets.winning_tickets.sum(:prize_amount) || 0
  end

  def active_subscriptions_count
    subscriptions.active_subscriptions.count
  end

  private

  def calculate_next_jackpot
    base_jackpot = odds_json&.dig("base_jackpot") || 1000.0

    # Add rollover from previous draws if no winners
    if latest_draw && latest_draw.total_winners == 0
      base_jackpot + latest_draw.jackpot_amount
    else
      base_jackpot
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
