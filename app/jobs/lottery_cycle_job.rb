class LotteryCycleJob < ApplicationJob
  queue_as :default

  def perform(lottery_id)
    # Find the lottery
    lottery = Lottery.find_by(id: lottery_id)
    return unless lottery
    return unless lottery.active? && lottery.is_endless

    # Increment the cycle count
    current_cycle = lottery.cycles_count
    lottery.update(cycles_count: current_cycle + 1)

    # Log the cycle change
    Rails.logger.info("Lottery ##{lottery.id} (#{lottery.name}) advanced to cycle #{current_cycle + 1}")

    # Schedule the next cycle (every 24 hours for MVP)
    # In a real implementation, this would be configurable
    LotteryCycleJob.set(wait: 24.hours).perform_later(lottery.id)
  end

  # Class method to schedule initial cycles for all endless lotteries
  # This would be called during application initialization
  def self.schedule_initial_cycles
    Lottery.where(status: :active, is_endless: true).find_each do |lottery|
      # Schedule the next cycle (random time within 24 hours for MVP to distribute load)
      delay = rand(24).hours
      LotteryCycleJob.set(wait: delay).perform_later(lottery.id)

      Rails.logger.info("Scheduled initial cycle for Lottery ##{lottery.id} (#{lottery.name}) in #{delay / 3600} hours")
    end
  end
end
