class AddReinvestedToPayoutLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :payout_logs, :reinvested, :boolean, default: false
  end
end
