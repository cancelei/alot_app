class DrawnNumber < ApplicationRecord
  # Associations
  belongs_to :lottery
  belongs_to :bet
  belongs_to :user

  # Validations
  validates :number, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :number, uniqueness: { scope: :bet_id, message: "has already been drawn for this bet" }
  validate :number_within_lottery_limit
  validate :bet_belongs_to_lottery
  validate :user_owns_bet

  # Scopes
  scope :for_lottery, ->(lottery_id) { where(lottery_id: lottery_id) }
  scope :for_bet, ->(bet_id) { where(bet_id: bet_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  # Class methods
  def self.winning_numbers_for_lottery(lottery_id)
    # This is a placeholder implementation - in a real app, this would
    # fetch the actual winning numbers from a blockchain or other source
    # For now, we'll simulate by using a deterministic algorithm based on the lottery ID
    lottery = Lottery.find(lottery_id)
    winning_set = Set.new

    # Generate a set of winning numbers based on the lottery ID
    # This is just for demonstration - in production this would come from the blockchain
    # Use cycle_number from the most recent bet or default to 1
    current_cycle = lottery.bets.maximum(:cycle_number) || 1
    seed = lottery_id * current_cycle
    Random.new(seed).rand(1..5).times do
      winning_set.add(Random.new(seed).rand(1..100))
    end

    winning_set.to_a
  end

  # Instance methods
  def winning?
    self.class.winning_numbers_for_lottery(lottery_id).include?(number)
  end

  private

  def number_within_lottery_limit
    return unless lottery && number

    if number > lottery.max_numbers_to_draw
      errors.add(:number, "exceeds the maximum allowed for this lottery (#{lottery.max_numbers_to_draw})")
    end
  end

  def bet_belongs_to_lottery
    return unless bet && lottery

    unless bet.lottery_id == lottery_id
      errors.add(:bet, "must belong to the same lottery")
    end
  end

  def user_owns_bet
    return unless bet && user

    unless bet.player_id == user.id
      errors.add(:user, "must be the owner of the bet")
    end
  end
end
