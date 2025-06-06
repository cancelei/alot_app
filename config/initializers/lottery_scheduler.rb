# Initialize lottery cycle scheduling for endless lotteries
Rails.application.config.after_initialize do
  # Only run in server mode, not during rake tasks or console
  if defined?(Rails::Server)
    Rails.logger.info("Scheduling initial lottery cycles for endless lotteries...")
    LotteryCycleJob.schedule_initial_cycles
  end
end
