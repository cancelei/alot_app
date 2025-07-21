class LotteryPolicy < ApplicationPolicy
  def index?
    true # All users can see the list of public lotteries
  end

  def show?
    # Users can view public lotteries or private lotteries they created
    record.public_lottery? || (user.super_admin? && record.created_by_id == user.id)
  end

  def create?
    user.super_admin? # Only super admins can create lotteries
  end

  def update?
    user.super_admin? && record.draft? # Only super admins can update draft lotteries
  end

  def destroy?
    user.super_admin? && record.draft? # Only super admins can delete draft lotteries
  end

  def publish?
    user.super_admin? && record.draft? # Only super admins can publish draft lotteries
  end

  def deploy_contract?
    user.super_admin? && record.active? && record.smart_contract_address.blank?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        # Super admins can see all lotteries
        scope.all
      else
        # Regular users can only see public lotteries
        scope.where(visibility: :public_lottery)
      end
    end
  end
end
