class PrizeClaim < ApplicationRecord
  belongs_to :user
  belongs_to :ticket
  belongs_to :draw
  belongs_to :lottery_game

  # Validations
  validates :prize_amount, presence: true, numericality: { greater_than: 0 }
  validates :claim_deadline, presence: true
  validates :status, presence: true
  validates :tax_withholding_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :auto_credited, -> { where(status: "auto_credited") }
  scope :manual_claim_required, -> { where(status: "manual_claim_required") }
  scope :claimed, -> { where(status: "claimed") }
  scope :expired, -> { where(status: "expired") }
  scope :expiring_soon, -> { where("claim_deadline <= ? AND status IN (?)", 30.days.from_now, [ "pending", "manual_claim_required" ]) }

  # Status helper methods
  def pending?
    status == "pending"
  end

  def auto_credited?
    status == "auto_credited"
  end

  def manual_claim_required?
    status == "manual_claim_required"
  end

  def claimed?
    status == "claimed"
  end

  def expired?
    status == "expired"
  end

  def can_auto_credit?
    # Auto-credit for prizes under $600 (IRS threshold)
    prize_amount < 600 && user.fully_verified?
  end

  def requires_tax_withholding?
    # Federal tax withholding required for prizes $5,000 and above
    prize_amount >= 5000
  end

  def requires_identity_verification?
    # Identity verification required for prizes $600 and above
    prize_amount >= 600
  end

  def days_until_expiration
    return 0 if expired? || claimed?
    [ (claim_deadline - Time.current).to_i / 1.day, 0 ].max
  end

  def expired_claim?
    claim_deadline < Time.current && !claimed?
  end

  def calculate_tax_withholding
    return 0 unless requires_tax_withholding?

    # Federal withholding: 24% for prizes $5,000+
    federal_withholding = prize_amount * 0.24

    # State withholding varies by jurisdiction
    state_rate = user.state_jurisdiction&.tax_withholding_rate || 0
    state_withholding = prize_amount * (state_rate / 100.0)

    federal_withholding + state_withholding
  end

  def net_prize_amount
    prize_amount - (tax_withholding_amount || 0)
  end

  def process_claim!
    return false if expired_claim? || claimed?

    transaction do
      if can_auto_credit?
        auto_credit_prize!
      else
        require_manual_claim!
      end
    end
  end

  def auto_credit_prize!
    return false unless can_auto_credit?

    # Credit user's account balance
    user.add_funds!(net_prize_amount)

    # Update claim status
    update!(
      status: "auto_credited",
      claimed_at: Time.current,
      processing_notes: "Auto-credited to account balance"
    )

    # Create payment record
    Payment.create!(
      user: user,
      ticket: ticket,
      amount: net_prize_amount,
      payment_type: "prize_credit",
      status: "completed",
      processed_at: Time.current
    )

    # Send notification
    # NotificationService.send_prize_credited(self)

    true
  end

  def require_manual_claim!
    # Calculate tax withholding if required
    if requires_tax_withholding?
      self.tax_withholding_amount = calculate_tax_withholding
    end

    update!(
      status: "manual_claim_required",
      processing_notes: "Manual claim required - prize amount: $#{prize_amount}"
    )

    # Send notification about manual claim requirement
    # NotificationService.send_manual_claim_required(self)

    true
  end

  def expire_claim!
    return false if claimed?

    update!(
      status: "expired",
      expired_at: Time.current,
      processing_notes: "Claim expired on #{claim_deadline.strftime('%B %d, %Y')}"
    )

    # Return unclaimed prize to prize pool or state fund
    # StateJurisdictionService.return_unclaimed_prize(self)

    true
  end

  def manual_claim_complete!(admin_user)
    return false unless manual_claim_required?

    transaction do
      # Credit user's account with net amount
      user.add_funds!(net_prize_amount)

      update!(
        status: "claimed",
        claimed_at: Time.current,
        processed_by: admin_user,
        processing_notes: "Manually processed by admin: #{admin_user.email}"
      )

      # Create payment record
      Payment.create!(
        user: user,
        ticket: ticket,
        amount: net_prize_amount,
        payment_type: "prize_claim",
        status: "completed",
        processed_at: Time.current
      )
    end

    # Send confirmation notification
    # NotificationService.send_prize_claimed(self)

    true
  end

  # Class methods for batch processing
  def self.process_pending_claims
    pending.find_each do |claim|
      claim.process_claim!
    end
  end

  def self.expire_old_claims
    where("claim_deadline < ? AND status IN (?)", Time.current, [ "pending", "manual_claim_required" ]).find_each do |claim|
      claim.expire_claim!
    end
  end

  def self.auto_credit_eligible_prizes
    pending.select(&:can_auto_credit?).each do |claim|
      claim.auto_credit_prize!
    end
  end
end
