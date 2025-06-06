class BetPolicy < ApplicationPolicy
  def show?
    # Users can only see their own bets or admins can see any bet
    user.super_admin? || record.player_id == user.id
  end

  def create?
    # Users can create bets on active public lotteries
    record.lottery.active? && record.lottery.visibility == "public_lottery"
  end

  def process_payout?
    # Only admins can process payouts
    user.super_admin? && record.won? && record.confirmed_on_chain? && !record.paid_out?
  end

  def process_payouts?
    # Only admins can process all pending payouts
    user.super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        # Admins can see all bets
        scope.all
      else
        # Regular users can only see their own bets
        scope.where(player_id: user.id)
      end
    end
  end
end
