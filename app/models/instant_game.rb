class InstantGame < ApplicationRecord
  has_many :scratch_offs, dependent: :destroy

  # No enums needed - using boolean is_active field from database

  # Validations
  validates :name, presence: true
  validates :ticket_price, presence: true, numericality: { greater_than: 0 }
  validates :total_tickets, presence: true, numericality: { greater_than: 0 }
  validates :top_prize, presence: true, numericality: { greater_than: 0 }
  validates :overall_odds, presence: true
  validates :prize_structure, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_price, ->(price) { where(ticket_price: price) }
  scope :available_for_purchase, -> { where(is_active: true).where("remaining_tickets > 0") }

  # Admin dashboard scope methods
  scope :active_games, -> { active }

  # Serialize prize structure as JSON
  serialize :prize_structure, coder: JSON

  # Instance methods
  def tickets_sold
    total_tickets - tickets_remaining
  end

  def tickets_remaining
    remaining_tickets
  end

  def top_prizes_remaining
    return 0 unless prize_structure.is_a?(Hash)

    top_prize_tier = prize_structure.keys.max_by(&:to_f)
    return 0 unless top_prize_tier

    claimed_top_prizes = scratch_offs.where(
      "prize_won >= ?", top_prize_tier.to_f
    ).count

    total_top_prizes = prize_structure[top_prize_tier]["quantity"] || 0
    [ total_top_prizes - claimed_top_prizes, 0 ].max
  end

  def calculate_odds_for_prize(prize_amount)
    return nil unless prize_structure.is_a?(Hash)

    prize_tier = prize_structure[prize_amount.to_s]
    return nil unless prize_tier

    quantity = prize_tier["quantity"] || 0
    return Float::INFINITY if quantity == 0

    total_tickets.to_f / quantity
  end

  def overall_win_rate
    return 0 if total_tickets == 0

    total_winning_tickets = prize_structure.values.sum { |tier| tier["quantity"] || 0 }
    (total_winning_tickets.to_f / total_tickets * 100).round(2)
  end

  def expected_payout_percentage
    return 0 if total_tickets == 0

    total_prize_value = prize_structure.sum do |prize_amount, tier_info|
      (prize_amount.to_f * (tier_info["quantity"] || 0))
    end

    total_revenue = total_tickets * ticket_price
    (total_prize_value / total_revenue * 100).round(2)
  end

  def can_purchase?
    is_active? && tickets_remaining > 0
  end

  def is_sold_out?
    tickets_remaining <= 0
  end

  def second_chance_eligible?
    second_chance_promotion.present?
  end

  def purchase_ticket!(user)
    return nil unless can_purchase?

    ActiveRecord::Base.transaction do
      # Decrement tickets remaining
      decrement!(:remaining_tickets)

      # Create scratch off ticket
      scratch_off = scratch_offs.create!(
        user: user,
        purchase_date: Time.current,
        prize_amount: 0.0,
        is_winner: false
      )

      # Generate winning/losing outcome
      scratch_off.generate_outcome!

      scratch_off
    end
  end

  # Admin methods for game management
  def pause_game!
    update!(is_active: false)
  end

  def resume_game!
    update!(is_active: true)
  end

  def end_game!
    update!(is_active: false)
  end

  def add_tickets!(quantity)
    increment!(:total_tickets, quantity)
    increment!(:remaining_tickets, quantity)
  end

  # Class methods for creating different price point games
  def self.create_dollar_game(params)
    default_structure = {
      "1.00" => { "quantity" => 100 },
      "2.00" => { "quantity" => 50 },
      "5.00" => { "quantity" => 20 },
      "10.00" => { "quantity" => 10 },
      "25.00" => { "quantity" => 4 },
      "100.00" => { "quantity" => 1 }
    }

    params.merge!(
      ticket_price: 1.00,
      prize_structure: (params[:prize_structure] || default_structure).to_json
    )
    create(params)
  end

  def self.create_five_dollar_game(params)
    default_structure = {
      "5.00" => { "quantity" => 200 },
      "10.00" => { "quantity" => 100 },
      "25.00" => { "quantity" => 40 },
      "50.00" => { "quantity" => 20 },
      "100.00" => { "quantity" => 10 },
      "1000.00" => { "quantity" => 2 }
    }

    params.merge!(
      ticket_price: 5.00,
      prize_structure: (params[:prize_structure] || default_structure).to_json
    )
    create(params)
  end

  def self.create_ten_dollar_game(params)
    default_structure = {
      "10.00" => { "quantity" => 300 },
      "20.00" => { "quantity" => 150 },
      "50.00" => { "quantity" => 60 },
      "100.00" => { "quantity" => 30 },
      "500.00" => { "quantity" => 6 },
      "5000.00" => { "quantity" => 1 }
    }

    params.merge!(
      ticket_price: 10.00,
      prize_structure: (params[:prize_structure] || default_structure).to_json
    )
    create(params)
  end

  private

  # Callbacks
  before_save :update_sold_out_status

  def update_sold_out_status
    if tickets_remaining <= 0
      self.is_active = false
    end
  end
end
