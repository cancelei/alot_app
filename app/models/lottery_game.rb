class LotteryGame < ApplicationRecord
  has_many :tickets, dependent: :destroy
  has_many :draws, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  # No enums needed - using string fields directly from database

  # Validations
  validates :name, presence: true
  validates :ticket_price, presence: true, numericality: { greater_than: 0 }
  validates :draw_frequency, presence: true, numericality: { greater_than: 0 }
  validates :jackpot_seed, presence: true, numericality: { greater_than: 0 }
  validates :prize_pool_percentage, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :number_range_min, presence: true, numericality: { greater_than: 0 }
  validates :number_range_max, presence: true, numericality: { greater_than: :number_range_min }
  validates :numbers_to_pick, presence: true, numericality: { greater_than: 0 }

  # Cycle management validations (temporarily commented out - fields may not exist in schema)
  # validates :cycle_length_minutes, presence: true, numericality: { greater_than: 0 }
  # validates :total_cycles, presence: true, numericality: { greater_than: 0 }
  # validates :payout_strategy, presence: true, inclusion: { in: %w[winner_takes_all proportional_refund admin_discretion] }

  validate :validate_rates_sum_not_exceed_one
  validate :validate_draw_frequency_for_game_type

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :rapid, -> { where(game_type: "rapid") }
  scope :hourly, -> { where(game_type: "hourly") }
  scope :daily, -> { where(game_type: "daily") }
  scope :weekly, -> { where(game_type: "weekly") }
  scope :progressive, -> { where(game_type: "progressive") }

  # Admin dashboard scope methods
  scope :active_games, -> { active }
  scope :rapid_games, -> { rapid }
  scope :official_games, -> { where(game_type: [ "powerball", "mega_millions" ]) }
  scope :custom_games, -> { where.not(game_type: [ "powerball", "mega_millions" ]) }

  # Instance methods
  def next_draw_time
    return next_draw_at if next_draw_at.present?
    return nil unless is_active?

    last_draw = draws.order(:draw_date).last
    base_time = last_draw&.draw_date || created_at

    base_time + draw_frequency.minutes
  end

  def current_prize_pool
    return current_jackpot if current_jackpot.present? && current_jackpot > 0

    base_amount = jackpot_seed

    # Add contributions from ticket sales since last draw
    last_draw = draws.where("draw_date <= ?", Time.current).order(:draw_date).last
    since_date = last_draw&.draw_date || created_at

    ticket_contributions = tickets.where("created_at > ?", since_date).sum(:cost) * (prize_pool_percentage / 100.0)

    # Add rollover from previous draws if no winners
    rollover = calculate_rollover_amount

    total = base_amount + ticket_contributions + rollover

    # Update current jackpot
    update_column(:current_jackpot, total) if total != current_jackpot

    total
  end

  def platform_revenue
    tickets.sum(:cost) * (1.0 - (prize_pool_percentage / 100.0))
  end

  def total_tickets_sold
    tickets.count
  end

  def average_tickets_per_draw
    return 0 if draws.completed.count == 0
    total_tickets_sold.to_f / draws.completed.count
  end

  def win_frequency
    winning_draws = draws.completed.joins(:tickets).where(tickets: { status: :won }).distinct.count
    total_draws = draws.completed.count

    return 0 if total_draws == 0
    (winning_draws.to_f / total_draws * 100).round(2)
  end

  def schedule_next_draw!
    return unless is_active?

    next_time = next_draw_time
    return if next_time.nil?

    # Don't create duplicate draws
    return if draws.where(draw_date: next_time).exists?

    draws.create!(
      draw_date: next_time,
      jackpot_amount: current_prize_pool,
      status: 0 # scheduled
    )

    # Update next_draw_at
    update_column(:next_draw_at, next_time + draw_frequency.minutes)
  end

  def can_purchase_tickets?
    is_active?
  end

  def time_until_next_draw
    next_time = next_draw_time
    return nil unless next_time

    seconds = (next_time - Time.current).to_i
    seconds > 0 ? seconds : 0
  end

  def is_rapid_game?
    draw_frequency <= 15
  end

  def is_official_game?
    game_type == "powerball" || game_type == "mega_millions"
  end

  def requires_official_integration?
    is_official_game?
  end

  # Cycle management methods
  def current_cycle_number
    return 1 unless cycle_start_time.present?

    elapsed_minutes = (Time.current - cycle_start_time) / 60.0
    cycle_number = (elapsed_minutes / cycle_length_minutes).floor + 1

    [ cycle_number, total_cycles ].min
  end

  def cycle_progress_percentage
    return 0 unless cycle_start_time.present?

    elapsed_minutes = (Time.current - cycle_start_time) / 60.0
    total_minutes = total_cycles * cycle_length_minutes

    progress = (elapsed_minutes / total_minutes * 100).round(2)
    [ progress, 100.0 ].min
  end

  def time_remaining_in_current_cycle
    return 0 unless cycle_start_time.present?

    current_cycle = current_cycle_number
    cycle_end_time = cycle_start_time + (current_cycle * cycle_length_minutes).minutes

    remaining = (cycle_end_time - Time.current).to_i
    [ remaining, 0 ].max
  end

  def total_cycle_time_remaining
    return 0 unless cycle_start_time.present?

    total_end_time = cycle_start_time + (total_cycles * cycle_length_minutes).minutes
    remaining = (total_end_time - Time.current).to_i

    [ remaining, 0 ].max
  end

  def cycles_completed?
    current_cycle_number >= total_cycles && total_cycle_time_remaining <= 0
  end

  def start_cycles!
    update!(
      cycle_start_time: Time.current,
      cycle_status: "active"
    )
  end

  def complete_cycles!
    return unless cycles_completed?

    # Process final payouts based on strategy
    case payout_strategy
    when "winner_takes_all"
      process_winner_takes_all_payout
    when "proportional_refund"
      process_proportional_refund
    when "admin_discretion"
      update!(cycle_status: "pending_admin_review")
      return
    end

    update!(cycle_status: "completed")
  end

  # Admin configuration helpers
  def self.create_rapid_game(params)
    params.merge!(
      game_type: "rapid",
      draw_frequency: params[:draw_frequency] || 5,
      is_active: false
    )
    create(params)
  end

  def self.create_hourly_game(params)
    params.merge!(
      game_type: "hourly",
      draw_frequency: 60,
      is_active: false
    )
    create(params)
  end

  def self.create_daily_game(params)
    params.merge!(
      game_type: "daily",
      draw_frequency: 1440, # 24 hours
      is_active: false
    )
    create(params)
  end

  def self.create_weekly_game(params)
    params.merge!(
      game_type: "weekly",
      draw_frequency: 10080, # 7 days
      is_active: false
    )
    create(params)
  end

  private

  def process_winner_takes_all_payout
    # Find the biggest winner in the current cycle
    cycle_tickets = tickets.where("created_at >= ?", cycle_start_time)
    winning_tickets = cycle_tickets.where(status: "won")

    if winning_tickets.any?
      biggest_winner = winning_tickets.order(prize_amount: :desc).first
      total_invested = cycle_tickets.sum(:cost)

      # Award the total invested amount to the biggest winner
      biggest_winner.update!(
        prize_amount: biggest_winner.prize_amount + total_invested,
        payout_status: "pending"
      )

      # Create payout log
      PayoutLog.create!(
        user: biggest_winner.user,
        ticket: biggest_winner,
        amount: total_invested,
        payout_type: "cycle_completion_winner_takes_all",
        status: "pending"
      )
    else
      # No winners - process refund
      process_proportional_refund
    end
  end

  def process_proportional_refund
    cycle_tickets = tickets.where("created_at >= ?", cycle_start_time)
    total_invested = cycle_tickets.sum(:cost)

    cycle_tickets.find_each do |ticket|
      refund_amount = ticket.cost # Full refund for fairness

      # Credit user account
      ticket.user.increment!(:account_balance, refund_amount)

      # Create payout log
      PayoutLog.create!(
        user: ticket.user,
        ticket: ticket,
        amount: refund_amount,
        payout_type: "cycle_completion_refund",
        status: "completed"
      )

      # Update ticket status
      ticket.update!(payout_status: "refunded")
    end
  end

  def calculate_rollover_amount
    # Get the last completed draw
    last_draw = draws.where("status = ? AND draw_date <= ?", 2, Time.current).order(:draw_date).last # completed
    return 0 unless last_draw

    # Count winning tickets for this draw
    winning_tickets = tickets.where(draw_id: last_draw.id, status: 1).count # won status

    # If there were no winners, add the jackpot to rollover
    if winning_tickets == 0
      case pool_reset_rule
      when "never_reset"
        last_draw.jackpot_amount
      when "reset_to_seed"
        0 # Reset to seed amount
      when "carry_forward"
        last_draw.jackpot_amount
      else
        0
      end
    else
      # If there were winners, apply jackpot increment for next draw
      last_draw.jackpot_amount * (jackpot_increment || 0)
    end
  end

  def validate_rates_sum_not_exceed_one
    if prize_pool_percentage > 100
      errors.add(:prize_pool_percentage, "cannot exceed 100%")
    end
  end

  def validate_draw_frequency_for_game_type
    case game_type
    when "rapid"
      unless draw_frequency.between?(1, 15)
        errors.add(:draw_frequency, "must be between 1 and 15 minutes for rapid games")
      end
    when "hourly"
      unless draw_frequency == 60
        errors.add(:draw_frequency, "must be 60 minutes for hourly games")
      end
    when "daily"
      unless draw_frequency == 1440
        errors.add(:draw_frequency, "must be 1440 minutes (24 hours) for daily games")
      end
    when "weekly"
      unless draw_frequency == 10080
        errors.add(:draw_frequency, "must be 10080 minutes (7 days) for weekly games")
      end
    end
  end
end
