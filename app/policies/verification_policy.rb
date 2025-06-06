class VerificationPolicy < ApplicationPolicy
  # For transparency, verification is public and accessible to all users
  # This aligns with the ethical lottery platform's transparency goals

  def verify_bet?
    # Anyone can verify a bet for transparency
    true
  end

  def verify_lottery?
    # Anyone can verify a lottery for transparency
    true
  end

  def verify_result?
    # Anyone can verify a result for transparency
    true
  end

  class Scope < Scope
    def resolve
      # All verifications are public for transparency
      scope.all
    end
  end
end
