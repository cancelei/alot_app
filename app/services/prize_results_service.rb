class PrizeResultsService
  include ActiveModel::Model

  def self.process_draw_results(draw)
    new.process_draw_results(draw)
  end

  def self.process_all_completed_draws
    Draw.completed.where(results_processed: [ nil, false ]).find_each do |draw|
      new.process_draw_results(draw)
    end
  end

  def process_draw_results(draw)
    return false unless draw.completed?

    Rails.logger.info "Processing results for Draw ##{draw.id} - #{draw.lottery_game.name}"

    ActiveRecord::Base.transaction do
      # Process all tickets for this draw
      winning_tickets = process_tickets_for_draw(draw)

      # Create prize claims for winning tickets
      create_prize_claims(winning_tickets, draw)

      # Update draw as processed
      draw.update!(results_processed: true, results_processed_at: Time.current)

      # Process auto-creditable prizes immediately
      process_auto_credit_prizes(draw)

      Rails.logger.info "Processed #{winning_tickets.count} winning tickets for Draw ##{draw.id}"
    end

    true
  rescue => e
    Rails.logger.error "Error processing draw results for Draw ##{draw.id}: #{e.message}"
    false
  end

  private

  def process_tickets_for_draw(draw)
    winning_tickets = []

    draw.tickets.includes(:user, :lottery_game).find_each do |ticket|
      if ticket.check_for_win(draw.winning_numbers_array)
        winning_tickets << ticket
        Rails.logger.info "Winning ticket found: Ticket ##{ticket.id}, Prize: $#{ticket.prize_amount}"
      end
    end

    winning_tickets
  end

  def create_prize_claims(winning_tickets, draw)
    winning_tickets.each do |ticket|
      next if ticket.prize_amount.nil? || ticket.prize_amount <= 0

      # Calculate claim deadline based on state jurisdiction
      claim_deadline = calculate_claim_deadline(ticket.user, draw.draw_date)

      prize_claim = PrizeClaim.create!(
        user: ticket.user,
        ticket: ticket,
        draw: draw,
        lottery_game: draw.lottery_game,
        prize_amount: ticket.prize_amount,
        claim_deadline: claim_deadline,
        status: "pending"
      )

      Rails.logger.info "Created PrizeClaim ##{prize_claim.id} for Ticket ##{ticket.id}"
    end
  end

  def calculate_claim_deadline(user, draw_date)
    # Default claim period is 180 days, but varies by state
    claim_period_days = user.state_jurisdiction&.claim_period_days || 180
    draw_date + claim_period_days.days
  end

  def process_auto_credit_prizes(draw)
    draw.prize_claims.pending.select(&:can_auto_credit?).each do |claim|
      if claim.auto_credit_prize!
        Rails.logger.info "Auto-credited prize claim ##{claim.id} for $#{claim.prize_amount}"
      end
    end
  end
end
