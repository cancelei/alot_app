class PrizeProcessingJob < ApplicationJob
  queue_as :default

  def perform(draw_id = nil)
    if draw_id
      # Process specific draw
      draw = Draw.find(draw_id)
      PrizeResultsService.process_draw_results(draw)
    else
      # Process all completed draws that haven't been processed
      PrizeResultsService.process_all_completed_draws

      # Process pending claims (auto-credit eligible)
      PrizeClaim.process_pending_claims

      # Expire old claims
      PrizeClaim.expire_old_claims
    end
  end
end
