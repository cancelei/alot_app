class FeatureRequestPolicy < ApplicationPolicy
  def index?
    true # All users can see feature requests
  end

  def show?
    user.super_admin? || record.submitted_by_id == user.id
  end

  def create?
    true # All users can create feature requests
  end

  def update?
    user.super_admin? # Only admins can update feature requests
  end

  def change_status?
    user.super_admin? # Only admins can change status
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        # Admins can see all feature requests
        scope.all
      else
        # Regular users can only see their own feature requests
        scope.where(submitted_by_id: user.id)
      end
    end
  end
end
