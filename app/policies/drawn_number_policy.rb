class DrawnNumberPolicy < ApplicationPolicy
  def create?
    # User must be logged in
    return false unless user

    # User must own the bet
    record.bet.player_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
