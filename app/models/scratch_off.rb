class ScratchOff < ApplicationRecord
  belongs_to :user
  belongs_to :instant_game
  has_many :payments, as: :payable, dependent: :destroy

  # Validations
  validates :purchase_date, presence: true
  validates :ticket_number, presence: true, uniqueness: true
  validates :prize_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :winning_tickets, -> { where(is_winner: true) }
  scope :unclaimed_winners, -> { where(is_winner: true, is_claimed: false) }
  scope :recent, -> { order(purchase_date: :desc) }

  # Instance methods
  def is_winner?
    prize_amount.present? && prize_amount > 0
  end

  def is_scratched?
    scratched? || won? || lost? || claimed?
  end

  def can_scratch?
    purchased? && !is_scratched?
  end

  def can_claim_prize?
    is_winner && prize_amount > 0
  end

  # Status helper methods (using boolean columns)
  def purchased?
    !is_scratched
  end

  def scratched?
    is_scratched
  end

  def won?
    is_winner
  end

  def lost?
    is_scratched && !is_winner
  end

  def claimed?
    is_claimed
  end

  def scratch!
    return false unless can_scratch?

    update!(is_scratched: true, scratch_date: Time.current)

    if is_winner?
      # Auto-credit small prizes (under $600)
      if prize_amount < 600
        claim_prize!
      end
    end

    true
  end

  def claim_prize!
    return false unless can_claim_prize?

    ActiveRecord::Base.transaction do
      # Create payment record for prize
      payment = payments.create!(
        amount: prize_amount,
        payment_type: "prize_payout",
        status: "completed",
        processed_at: Time.current
      )

      # Credit user's account
      user.add_funds!(prize_amount) if user.respond_to?(:add_funds!)

      # Update status
      update!(is_claimed: true, claim_date: Time.current)

      # Handle tax implications for prizes >= $600
      if prize_amount >= 600
        create_tax_document!
      end
    end

    true
  end

  def generate_outcome!
    return if is_scratched?

    # Use the instant game's prize structure to determine outcome
    prize_structure = instant_game.prize_structure
    return unless prize_structure.is_a?(Hash)

    # Calculate total winning tickets for probability
    total_winning_tickets = prize_structure.values.sum { |tier| tier["quantity"] || 0 }
    total_tickets = instant_game.total_tickets

    # Generate random outcome
    random_value = rand(total_tickets)

    if random_value < total_winning_tickets
      # This is a winner - determine prize amount
      self.prize_won = determine_prize_amount(prize_structure)
    else
      # This is a loser
      self.prize_won = 0
    end

    save!
  end

  def ticket_image_url
    # Generate a unique ticket image URL based on instant game design
    return nil unless instant_game

    base_url = "/images/scratch_offs/#{instant_game.id}"
    ticket_id = id || SecureRandom.uuid

    if is_scratched?
      "#{base_url}/scratched_#{ticket_id}.png"
    else
      "#{base_url}/unscratched_#{ticket_id}.png"
    end
  end

  def scratch_areas
    # Define scratchable areas for the digital experience
    # This would be customized per instant game design
    [
      { x: 50, y: 100, width: 80, height: 40, revealed: is_scratched? },
      { x: 150, y: 100, width: 80, height: 40, revealed: is_scratched? },
      { x: 250, y: 100, width: 80, height: 40, revealed: is_scratched? }
    ]
  end

  def time_to_claim_expires
    return nil unless won?

    claim_period = instant_game.state_jurisdiction.claim_period_days
    purchase_date + claim_period.days
  end

  def claim_expired?
    return false unless won?

    expiry_date = time_to_claim_expires
    expiry_date && expiry_date < Date.current
  end

  def second_chance_eligible?
    lost? && instant_game.second_chance_eligible?
  end

  def enter_second_chance!
    return false unless second_chance_eligible?

    # Logic for entering second chance drawings
    # This would integrate with the instant game's second chance promotion
    update!(second_chance_entered: true, second_chance_entered_at: Time.current)
  end

  # Display methods
  def prize_display
    return "No Prize" unless is_winner?

    if prize_won >= 1000
      "$#{(prize_won / 1000).round(1)}K"
    else
      "$#{prize_won.to_i}"
    end
  end

  def status_display
    case status
    when "purchased"
      "Ready to Scratch"
    when "scratched"
      "Scratched"
    when "won"
      "Winner - #{prize_display}"
    when "lost"
      "Not a Winner"
    when "claimed"
      "Claimed - #{prize_display}"
    else
      status.humanize
    end
  end

  private

  def determine_prize_amount(prize_structure)
    # Weighted random selection based on prize structure
    prizes = []

    prize_structure.each do |amount, tier_info|
      quantity = tier_info["quantity"] || 0
      quantity.times { prizes << amount.to_f }
    end

    return 0 if prizes.empty?

    prizes.sample
  end

  def create_tax_document!
    return unless prize_won >= 600

    # Create W-2G tax document for winnings >= $600
    # This would integrate with tax document generation system
    tax_doc_params = {
      user: user,
      prize_amount: prize_won,
      tax_year: Date.current.year,
      game_type: "instant",
      game_name: instant_game.name,
      win_date: scratched_at || Time.current
    }

    # TaxDocument.create!(tax_doc_params) # Would be implemented separately
  end
end
