class StateJurisdiction < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :lottery_games, dependent: :restrict_with_error

  # Validations
  validates :state_code, presence: true, uniqueness: true, length: { is: 2 }
  validates :state_name, presence: true, uniqueness: true
  validates :minimum_age, presence: true, inclusion: { in: [ 18, 21 ] }
  validates :tax_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :lottery_legal, -> { where(lottery_legal: true) }

  # Class methods
  def self.for_user_location(latitude, longitude)
    # This would integrate with a geolocation service to determine state
    # For now, return a default or require manual selection
    nil
  end

  # Instance methods
  def display_name
    "#{state_name} (#{state_code})"
  end

  def allows_online_lottery?
    lottery_legal && is_active
  end

  def federal_tax_withholding_threshold
    600.0 # Federal threshold for tax withholding
  end

  def state_tax_withholding_threshold
    winnings_threshold || 600.0
  end

  def calculate_tax_withholding(prize_amount)
    return 0 if prize_amount < federal_tax_withholding_threshold

    federal_tax = prize_amount >= 5000 ? prize_amount * 0.24 : 0
    state_tax = prize_amount >= state_tax_withholding_threshold ? prize_amount * tax_rate : 0

    {
      federal: federal_tax,
      state: state_tax,
      total: federal_tax + state_tax
    }
  end

  def claim_period_days
    claim_period || 180 # Default 180 days
  end
end
