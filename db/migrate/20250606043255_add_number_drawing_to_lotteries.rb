class AddNumberDrawingToLotteries < ActiveRecord::Migration[8.0]
  def change
    add_column :lotteries, :max_numbers_to_draw, :integer, default: 5
    add_column :lotteries, :cost_per_number, :decimal, precision: 15, scale: 2, default: 1.0
  end
end
