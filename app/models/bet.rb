class Bet < ApplicationRecord
  belongs_to :player, class_name: "User"
  belongs_to :lottery
  has_many :drawn_numbers, dependent: :destroy
  has_many :payout_logs, dependent: :nullify

  # Enums
  enum "result", { pending: 0, won: 1, lost: 2, failed: 3 }

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :cycle_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :signed_transaction_payload, presence: true

  # Scopes
  scope :pending_bets, -> { where(result: :pending) }
  scope :won_bets, -> { where(result: :won) }
  scope :lost_bets, -> { where(result: :lost) }
  scope :failed_bets, -> { where(result: :failed) }
  scope :confirmed_bets, -> { where(confirmed_on_chain: true) }

  # Alias for player to maintain compatibility with views expecting 'user'
  def user
    player
  end

  # Check if the bet has been paid out
  def paid_out?
    payout_logs.exists?
  end

  # Instance methods
  def winning_numbers
    winning_set = DrawnNumber.winning_numbers_for_lottery(lottery_id)
    drawn_numbers.select { |dn| winning_set.include?(dn.number) }
  end

  def has_winning_numbers?
    winning_numbers.any?
  end

  def calculate_winnings
    return 0 unless confirmed_on_chain && has_winning_numbers?

    # Calculate winnings based on the lottery's payout strategy
    # This is a simplified implementation
    base_winnings = amount * lottery.odds_json["payout_multiplier"].to_f

    # Bonus for each winning number
    winning_bonus = winning_numbers.count * lottery.cost_per_number * 2

    base_winnings + winning_bonus
  end

  # Callbacks
  before_validation :set_defaults

  private

  def set_defaults
    self.result ||= :pending
    self.confirmed_on_chain ||= false
  end
end
