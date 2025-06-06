class LotteryResult < ApplicationRecord
  belongs_to :lottery

  # Validations
  validates :cycle_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :winning_number, presence: true
  validates :result_hash, presence: true, uniqueness: true
  validates :cycle_number, uniqueness: { scope: :lottery_id, message: "should have only one result per lottery cycle" }

  # Scopes
  scope :by_lottery, ->(lottery_id) { where(lottery_id: lottery_id) }
  scope :by_cycle, ->(cycle_number) { where(cycle_number: cycle_number) }
  scope :verified, -> { where.not(verified_at: nil) }

  # Methods

  # Check if the result has been verified
  def verified?
    verified_at.present?
  end

  # Verify the result hash to ensure integrity
  def verify_result_hash
    # In MVP, we'll use a simple verification
    # In Phase 2, this would verify against blockchain data
    expected_hash = generate_expected_hash

    if result_hash == expected_hash
      update(verified_at: Time.current) unless verified?
      true
    else
      false
    end
  end

  # Generate the expected hash for verification
  def generate_expected_hash
    # This should match the hash generation in LotteryResultProcessingJob
    data = {
      lottery_id: lottery_id,
      cycle_number: cycle_number,
      winning_number: winning_number,
      timestamp: created_at.to_i
    }

    Digest::SHA256.hexdigest(data.to_json)
  end

  # Get the verification steps for transparency
  def verification_steps
    [
      {
        step: 1,
        title: "Lottery Information",
        description: "Verify the lottery details",
        data: {
          lottery_id: lottery_id,
          lottery_name: lottery.name,
          cycle_number: cycle_number
        }
      },
      {
        step: 2,
        title: "Random Number Generation",
        description: "Verify the source of randomness",
        data: {
          randomness_source: lottery.randomness_source,
          winning_number: winning_number
        }
      },
      {
        step: 3,
        title: "Result Hash Verification",
        description: "Verify the integrity of the result",
        data: {
          result_hash: result_hash,
          verification_method: "SHA-256 hash of lottery data"
        }
      },
      {
        step: 4,
        title: "Timestamp Verification",
        description: "Verify when the result was generated",
        data: {
          created_at: created_at,
          verified_at: verified_at
        }
      }
    ]
  end

  # Get blockchain explorer URL for verification
  # In MVP this is simulated, in Phase 2 it would link to actual blockchain explorer
  def blockchain_explorer_url
    "https://etherscan.io/tx/#{result_hash}"
  end
end
