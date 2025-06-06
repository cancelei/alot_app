class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Define roles
  enum "role", { player: 0, super_admin: 1 }

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true, length: { minimum: 2, maximum: 50 }, allow_blank: false

  # Set default role
  after_initialize :set_default_role, if: :new_record?

  # Associations for admin
  has_many :created_lotteries, class_name: "Lottery", foreign_key: "created_by_id", dependent: :nullify

  # Associations for player
  has_many :bets, foreign_key: "player_id", dependent: :nullify
  has_many :drawn_numbers, dependent: :destroy
  has_many :feature_requests, foreign_key: "submitted_by_id", dependent: :nullify

  # Blockchain wallet integration (placeholder for Phase 2)
  # These fields will be added in future migrations
  # - wallet_address:string - to store the user's blockchain wallet address
  # - wallet_type:string - to identify which blockchain network (Polkadot, Ethereum, etc.)
  # - wallet_verified:boolean - to track verification status

  # Method to check if user has a connected wallet (for future use)
  def wallet_connected?
    false # Will be implemented in Phase 2
  end

  private

  def set_default_role
    self.role ||= :player
  end
end
