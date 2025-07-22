class Payment < ApplicationRecord
  belongs_to :user
  belongs_to :ticket, optional: true
  belongs_to :subscription, optional: true

  # Status helper methods (replacing enum to avoid conflicts)
  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def refunded?
    status == "refunded"
  end
  enum "payment_method", {
    account_balance: 0,
    credit_card: 1,
    debit_card: 2,
    digital_wallet: 3,
    ach: 4
  }

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true
  validates :transaction_id, uniqueness: true, allow_blank: true
  validate :has_ticket_or_subscription

  # Scopes
  scope :completed_payments, -> { where(status: "completed") }
  scope :failed_payments, -> { where(status: "failed") }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_tickets, -> { where.not(ticket_id: nil) }
  scope :for_subscriptions, -> { where.not(subscription_id: nil) }

  # Instance methods
  def process!
    return false unless pending?

    update!(status: "processing")

    case payment_method
    when "account_balance"
      process_account_balance_payment
    when "credit_card", "debit_card"
      process_card_payment
    when "digital_wallet"
      process_digital_wallet_payment
    when "ach"
      process_ach_payment
    else
      update!(status: :failed)
      false
    end
  end

  def refund!(reason = nil)
    return false unless completed?

    transaction do
      if payment_method == "account_balance"
        # Refund to account balance
        user.increment!(:account_balance, amount)
        update!(status: "refunded", processed_at: Time.current)
        true
      else
        # Process external refund (to be implemented with payment processor)
        # PaymentService.process_refund(self, reason)
        update!(status: "refunded", processed_at: Time.current)
        true
      end
    end
  rescue => e
    Rails.logger.error "Refund failed: #{e.message}"
    false
  end

  def can_refund?
    completed? && processed_at > 30.days.ago
  end

  def payment_description
    if ticket
      "Lottery ticket for #{ticket.lottery.name}"
    elsif subscription
      "Subscription payment for #{subscription.lottery.name}"
    else
      "Payment"
    end
  end

  def formatted_amount
    "$#{amount.to_f.round(2)}"
  end

  private

  def has_ticket_or_subscription
    if ticket.blank? && subscription.blank?
      errors.add(:base, "Payment must be associated with either a ticket or subscription")
    end
  end

  def process_account_balance_payment
    if user.account_balance >= amount
      user.decrement!(:account_balance, amount)
      update!(status: "completed", processed_at: Time.current, transaction_id: generate_transaction_id)
      true
    else
      update!(status: :failed)
      false
    end
  end

  def process_card_payment
    # Placeholder for external payment processor integration
    # In real implementation, this would integrate with Stripe, etc.
    update!(status: "completed", processed_at: Time.current, transaction_id: generate_transaction_id)
    true
  end

  def process_digital_wallet_payment
    # Placeholder for digital wallet payment processing
    update!(status: "completed", processed_at: Time.current, transaction_id: generate_transaction_id)
    true
  end

  def process_ach_payment
    # Placeholder for ACH payment processing
    update!(status: "completed", processed_at: Time.current, transaction_id: generate_transaction_id)
    true
  end

  def generate_transaction_id
    "TXN_#{Time.current.to_i}_#{SecureRandom.hex(8)}"
  end
end
