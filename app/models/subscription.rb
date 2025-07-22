class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :lottery_game
  has_many :tickets, dependent: :nullify
  has_many :payments, dependent: :nullify

  # Status helper methods (replacing enum to avoid conflicts)
  def active?
    status == "active"
  end

  def paused?
    status == "paused"
  end

  def cancelled?
    status == "cancelled"
  end

  def expired?
    status == "expired"
  end
  enum "frequency", { weekly: 0, bi_weekly: 1, monthly: 2 }

  # Validations
  validates :frequency, presence: true
  validates :next_purchase_date, presence: true
  validates :auto_renew, inclusion: { in: [ true, false ] }
  validate :next_purchase_date_in_future, on: :create

  # Scopes
  scope :active_subscriptions, -> { where(status: :active) }
  scope :due_for_purchase, -> { where("next_purchase_date <= ?", Time.current) }
  scope :expiring_soon, -> { where("next_purchase_date BETWEEN ? AND ?", Time.current, 7.days.from_now) }

  # Instance methods
  def can_purchase_ticket?
    active? && next_purchase_date <= Time.current
  end

  def purchase_next_ticket!
    return false unless can_purchase_ticket?

    transaction do
      # Find or create next draw for this lottery
      next_draw = lottery.draws.upcoming.first || lottery.create_next_draw

      # Create ticket with user's preferred numbers or quick pick
      ticket = tickets.create!(
        user: user,
        lottery: lottery,
        draw: next_draw,
        numbers: generate_subscription_numbers,
        purchase_date: Time.current,
        cost: lottery.ticket_cost,
        status: :pending
      )

      # Process payment
      payment = process_subscription_payment(ticket)

      if payment&.completed?
        ticket.update!(status: :active)
        update_next_purchase_date!
        true
      else
        ticket.destroy
        false
      end
    end
  rescue => e
    Rails.logger.error "Subscription purchase failed: #{e.message}"
    false
  end

  def cancel!
    update!(status: :cancelled, auto_renew: false)
  end

  def pause!
    update!(status: :paused)
  end

  def resume!
    return false unless paused?

    update!(status: :active, next_purchase_date: calculate_next_purchase_date)
  end

  def days_until_next_purchase
    return 0 if next_purchase_date <= Time.current
    (next_purchase_date.to_date - Date.current).to_i
  end

  def total_spent
    payments.completed.sum(:amount) || 0
  end

  def total_winnings
    tickets.winning_tickets.sum(:prize_amount) || 0
  end

  private

  def next_purchase_date_in_future
    return unless next_purchase_date

    if next_purchase_date <= Time.current
      errors.add(:next_purchase_date, "must be in the future")
    end
  end

  def generate_subscription_numbers
    # For now, generate quick pick numbers
    # Later can be enhanced to use user's favorite numbers
    (1..lottery.max_number).to_a.sample(lottery.numbers_to_draw).sort
  end

  def process_subscription_payment(ticket)
    # Use user's account balance first, then default payment method
    payment_amount = ticket.cost

    if user.account_balance >= payment_amount
      # Deduct from account balance
      user.decrement!(:account_balance, payment_amount)

      payments.create!(
        user: user,
        amount: payment_amount,
        payment_method: "account_balance",
        status: :completed,
        processed_at: Time.current
      )
    else
      # Process with external payment method (to be implemented)
      # PaymentService.process_subscription_payment(self, ticket)
      nil
    end
  end

  def update_next_purchase_date!
    self.next_purchase_date = calculate_next_purchase_date
    save!
  end

  def calculate_next_purchase_date
    case frequency
    when "weekly"
      next_purchase_date + 1.week
    when "bi_weekly"
      next_purchase_date + 2.weeks
    when "monthly"
      next_purchase_date + 1.month
    end
  end
end
