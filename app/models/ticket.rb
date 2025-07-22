class Ticket < ApplicationRecord
  belongs_to :user
  belongs_to :lottery_game
  belongs_to :draw, optional: true
  belongs_to :subscription, optional: true
  has_many :payments, dependent: :nullify
  has_one :prize_claim, dependent: :destroy

  # Validations
  validates :numbers, presence: true
  validates :purchase_date, presence: true
  validates :cost, presence: true, numericality: { greater_than: 0 }
  validates :prize_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active_tickets, -> { where(status: [ "pending", "active" ]) }
  scope :winning_tickets, -> { where(status: "won") }
  scope :for_upcoming_draws, -> { joins(:draw).where("draws.draw_date > ?", Time.current) }
  scope :recent, -> { order(purchase_date: :desc) }

  # Serialize numbers as JSON array
  serialize :numbers, coder: JSON

  # Instance methods
  def numbers_array
    numbers.is_a?(Array) ? numbers : JSON.parse(numbers || "[]")
  end

  def numbers_display
    numbers_array.sort.join(", ")
  end

  def check_for_win(winning_numbers)
    return false unless draw&.status == "completed"

    winning_array = winning_numbers.is_a?(Array) ? winning_numbers : JSON.parse(winning_numbers || "[]")
    matches = (numbers_array & winning_array).length

    # Update status and prize based on matches
    if matches >= lottery.min_matches_to_win
      self.status = "won"
      self.prize_amount = calculate_prize(matches)
      save!
      true
    else
      self.status = "lost"
      save!
      false
    end
  end

  def time_until_draw
    return nil unless draw&.draw_date
    return 0 if draw.draw_date <= Time.current

    (draw.draw_date - Time.current).to_i
  end

  def can_claim_prize?
    won? && prize_amount&.positive? && !prize_claimed?
  end

  def prize_claimed?
    payments.where(status: "completed").sum(:amount) >= (prize_amount || 0)
  end

  # Status helper methods (replacing removed enum)
  def pending?
    status == "pending"
  end

  def active?
    status == "active"
  end

  def won?
    status == "won"
  end

  def lost?
    status == "lost"
  end

  def expired?
    status == "expired"
  end

  private

  def calculate_prize(matches)
    # Basic prize calculation - can be enhanced based on lottery rules
    base_prize = cost * lottery.prize_multiplier_for_matches(matches)
    base_prize
  end
end
