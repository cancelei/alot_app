class AddVerificationDataToLotteries < ActiveRecord::Migration[8.0]
  def change
    add_column :lotteries, :verification_data, :jsonb
  end
end
