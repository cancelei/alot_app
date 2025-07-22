class IdentityVerification < ApplicationRecord
  belongs_to :user

  # Enums
  enum "status", { pending: 0, verified: 1, rejected: 2, expired: 3 }
  # Note: verification_type is a string field, not an enum

  # Validations
  validates :ssn_last_four, presence: true, length: { is: 4 }, format: { with: /\A\d{4}\z/ }
  validates :address_line1, presence: true
  validates :city, presence: true
  validates :state, presence: true, length: { is: 2 }
  validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/ }
  validates :status, presence: true

  # Scopes
  scope :verified_users, -> { where(status: :verified) }
  scope :pending_verification, -> { where(status: :pending) }

  # Instance methods
  def full_address
    address_parts = [ address_line1 ]
    address_parts << address_line2 if address_line2.present?
    address_parts << "#{city}, #{state} #{zip_code}"
    address_parts.join(", ")
  end

  def verification_complete?
    verified? && verification_date.present?
  end

  def verification_expired?
    return false unless verification_date

    # Verification expires after 2 years for tax compliance
    verification_date < 2.years.ago
  end

  def can_receive_tax_documents?
    verification_complete? && !verification_expired?
  end

  def masked_ssn
    "***-**-#{ssn_last_four}"
  end

  # Callbacks
  before_save :set_verification_date, if: :will_save_change_to_status?

  private

  def set_verification_date
    if status == "verified"
      self.verification_date = Time.current
    elsif status == "rejected"
      self.verification_date = nil
    end
  end
end
