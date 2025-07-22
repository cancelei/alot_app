class Draw < ApplicationRecord
  belongs_to :lottery_game
  has_many :tickets, dependent: :nullify
  has_many :prize_claims, dependent: :destroy

  # Status helper methods (replacing enum to avoid conflicts)
  def scheduled?
    status == "scheduled"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  # Validations
  validates :draw_date, presence: true
  validates :jackpot_amount, presence: true, numericality: { greater_than: 0 }
  validate :draw_date_in_future, on: :create
  validate :winning_numbers_format, if: :completed?

  # Scopes
  scope :upcoming, -> { where("draw_date > ?", Time.current) }
  scope :past, -> { where("draw_date <= ?", Time.current) }
  scope :completed, -> { where(status: "completed") }
  scope :scheduled, -> { where(status: "scheduled") }
  scope :recent_results, -> { completed.order(draw_date: :desc) }
  scope :next_draw, -> { upcoming.order(:draw_date).first }

  # Serialize winning numbers as JSON array
  serialize :winning_numbers, coder: JSON

  # Instance methods
  def winning_numbers_array
    winning_numbers.is_a?(Array) ? winning_numbers : JSON.parse(winning_numbers || "[]")
  end

  def winning_numbers_display
    return "Not drawn yet" unless completed?
    winning_numbers_array.sort.join(", ")
  end

  def time_until_draw
    return 0 if draw_date <= Time.current
    (draw_date - Time.current).to_i
  end

  def can_conduct_draw?
    scheduled? && draw_date <= Time.current
  end

  def conduct_draw!
    return false unless can_conduct_draw?

    transaction do
      # Generate winning numbers based on lottery rules
      self.winning_numbers = generate_winning_numbers
      self.status = "completed"
      save!

      # Check all tickets for this draw
      check_all_tickets_for_wins

      # Process prize claims for winning tickets
      PrizeProcessingJob.perform_later(id)

      # Send notifications (will be implemented with notification system)
      # NotificationService.send_draw_results(self)
    end

    true
  end

  def total_winners
    tickets.winning_tickets.count
  end

  def total_prize_amount
    tickets.winning_tickets.sum(:prize_amount) || 0
  end

  private

  def draw_date_in_future
    return unless draw_date

    if draw_date <= Time.current
      errors.add(:draw_date, "must be in the future")
    end
  end

  def winning_numbers_format
    return unless winning_numbers

    numbers_array = winning_numbers_array

    if numbers_array.length != lottery_game.numbers_to_draw
      errors.add(:winning_numbers, "must contain exactly #{lottery_game.numbers_to_draw} numbers")
    end

    if numbers_array.any? { |n| !n.is_a?(Integer) || n < 1 || n > lottery_game.max_number }
      errors.add(:winning_numbers, "must be integers between 1 and #{lottery_game.max_number}")
    end

    if numbers_array.uniq.length != numbers_array.length
      errors.add(:winning_numbers, "cannot contain duplicate numbers")
    end
  end

  def generate_winning_numbers
    # Generate random winning numbers based on lottery configuration
    (1..lottery_game.max_number).to_a.sample(lottery_game.numbers_to_draw).sort
  end

  def check_all_tickets_for_wins
    tickets.find_each do |ticket|
      ticket.check_for_win(winning_numbers_array)
    end
  end
end
