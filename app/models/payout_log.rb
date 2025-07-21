class PayoutLog < ApplicationRecord
  belongs_to :lottery
  belongs_to :player, class_name: "User"
  belongs_to :bet

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :cycle_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :transaction_hash, presence: true, uniqueness: true, if: -> { transaction_hash.present? }

  # Scopes
  scope :by_lottery, ->(lottery_id) { where(lottery_id: lottery_id) }
  scope :by_player, ->(player_id) { where(player_id: player_id) }
  scope :by_cycle, ->(cycle_number) { where(cycle_number: cycle_number) }

  # Methods
  def verified_on_chain?
    transaction_hash.present?
  end

  # Alias for compatibility with views
  def confirmed_on_chain?
    verified_on_chain?
  end
end
