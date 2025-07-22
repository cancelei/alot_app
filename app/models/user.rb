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
  validates :username, presence: true, uniqueness: true,
            length: { minimum: 3, maximum: 30 },
            format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters, numbers, and underscores" },
            allow_blank: false,
            if: :username_required?

  # Prevent username from being changed after creation
  attr_readonly :username

  # Set default role
  after_initialize :set_default_role, if: :new_record?

  # Associations for admin
  has_many :created_lotteries, class_name: "Lottery", foreign_key: "created_by_id", dependent: :nullify

  # Associations for player
  has_many :bets, foreign_key: "player_id", dependent: :nullify
  has_many :drawn_numbers, dependent: :destroy
  has_many :feature_requests, foreign_key: "submitted_by_id", dependent: :nullify

  # New associations for redesigned lottery system
  belongs_to :state_jurisdiction, optional: true
  has_one :identity_verification, dependent: :destroy
  has_many :tickets, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :scratch_offs, dependent: :destroy
  has_many :prize_claims, dependent: :destroy
  has_many :created_lottery_games, class_name: "LotteryGame", foreign_key: "created_by_id", dependent: :nullify
  has_many :created_instant_games, class_name: "InstantGame", foreign_key: "created_by_id", dependent: :nullify

  # Blockchain wallet integration (placeholder for Phase 2)
  # These fields will be added in future migrations
  # - wallet_address:string - to store the user's blockchain wallet address
  # - wallet_type:string - to identify which blockchain network (Polkadot, Ethereum, etc.)
  # - wallet_verified:boolean - to track verification status

  # Method to check if user has a connected wallet (for future use)
  def wallet_connected?
    false # Will be implemented in Phase 2
  end

  # New methods for lottery app redesign
  def age_verified?
    date_of_birth.present? && age >= 18
  end

  def age
    return 0 unless date_of_birth
    ((Date.current - date_of_birth) / 365.25).floor
  end

  def fully_verified?
    age_verified? && location_verified? && identity_verified? && state_jurisdiction.present?
  end

  def onboarding_complete?
    fully_verified? && name.present? && username.present?
  end

  def can_purchase_tickets?
    fully_verified? && account_balance.positive? && !self_excluded? && state_allows_online_lottery?
  end

  def total_spent
    payments.completed_payments.sum(:amount) || 0
  end

  def total_winnings
    tickets.winning_tickets.sum(:prize_amount) || 0
  end

  def active_tickets_count
    tickets.active_tickets.count
  end

  def winning_tickets_count
    tickets.winning_tickets.count
  end

  def add_funds!(amount)
    increment!(:account_balance, amount)
  end

  def can_spend?(amount)
    return false unless amount.positive?

    # Check account balance
    return false if account_balance < amount

    # Check daily spending limit
    if spending_limit_daily.present?
      daily_spent = payments.completed_payments.where("created_at >= ?", Date.current.beginning_of_day).sum(:amount)
      return false if (daily_spent + amount) > spending_limit_daily
    end

    # Check weekly spending limit
    if spending_limit_weekly.present?
      weekly_spent = payments.completed_payments.where("created_at >= ?", Date.current.beginning_of_week).sum(:amount)
      return false if (weekly_spent + amount) > spending_limit_weekly
    end

    # Check monthly spending limit
    if spending_limit_monthly.present?
      monthly_spent = payments.completed_payments.where("created_at >= ?", Date.current.beginning_of_month).sum(:amount)
      return false if (monthly_spent + amount) > spending_limit_monthly
    end

    true
  end

  # American lottery compliance methods
  def state_allows_online_lottery?
    state_jurisdiction&.allows_online_lottery? || false
  end

  def self_excluded?
    self_excluded == true
  end

  def requires_identity_verification?
    total_winnings >= 600 || total_spent >= 2400 # IRS thresholds
  end

  def can_claim_large_prizes?
    identity_verification&.verification_complete? && !identity_verification&.verification_expired?
  end

  def set_spending_limits!(daily: nil, weekly: nil, monthly: nil)
    update!(
      spending_limit_daily: daily,
      spending_limit_weekly: weekly,
      spending_limit_monthly: monthly,
      responsible_gaming_limits_set: true
    )
  end

  def set_self_exclusion!(duration_days)
    update!(
      self_exclusion_until: duration_days.days.from_now,
      last_activity_at: Time.current
    )
  end

  def total_instant_winnings
    scratch_offs.winning_tickets.sum(:prize_won) || 0
  end

  def total_draw_winnings
    tickets.winning_tickets.sum(:prize_amount) || 0
  end

  def update_last_activity!
    update_column(:last_activity_at, Time.current)
  end

  private

  def set_default_role
    self.role ||= :player
  end

  def username_required?
    new_record? || username_changed?
  end
end
