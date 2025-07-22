# Sample Lottery Games Seed Data for American Lottery System
# Creates various types of lottery games matching the PRD requirements

puts "Creating sample lottery games..."

# Rapid Game (5-minute draws)
rapid_game = LotteryGame.create!(
  name: "Lightning 5",
  description: "Fast-paced lottery with draws every 5 minutes! Pick 5 numbers from 1-35.",
  game_type: "rapid",
  draw_frequency: 5, # 5 minutes
  ticket_price: 2.00,
  numbers_to_pick: 5,
  number_range_min: 1,
  number_range_max: 35,
  bonus_ball: false,
  multiplier_available: true,
  multiplier_cost: 1.00,
  prize_pool_percentage: 50.0,
  jackpot_seed: 10000.0,
  jackpot_increment: 0.30,
  winner_selection_mode: "guaranteed_winner",
  pool_reset_rule: "reset_to_seed",
  max_jackpot: 100000.0,
  is_active: true,
  created_by: "System"
)

# Hourly Game
hourly_game = LotteryGame.create!(
  name: "Power Hour",
  description: "Hourly draws with growing jackpots! Pick 6 numbers from 1-49 plus a bonus ball.",
  game_type: "hourly",
  draw_frequency: 60, # 60 minutes
  ticket_price: 5.00,
  numbers_to_pick: 6,
  number_range_min: 1,
  number_range_max: 49,
  bonus_ball: true,
  bonus_range_min: 1,
  bonus_range_max: 10,
  multiplier_available: true,
  multiplier_cost: 2.00,
  prize_pool_percentage: 60.0,
  jackpot_seed: 50000.0,
  jackpot_increment: 0.40,
  winner_selection_mode: "traditional",
  pool_reset_rule: "reset_to_seed",
  max_jackpot: 1000000.0,
  is_active: true,
  created_by: "System"
)

# Daily Game (similar to Pick 3/Pick 4)
daily_game = LotteryGame.create!(
  name: "Daily Numbers",
  description: "Classic daily draw game! Pick 4 numbers from 1-9.",
  game_type: "daily",
  draw_frequency: 1440, # 24 hours (1440 minutes)
  ticket_price: 1.00,
  numbers_to_pick: 4,
  number_range_min: 1,
  number_range_max: 9,
  bonus_ball: false,
  multiplier_available: false,
  prize_pool_percentage: 50.0,
  jackpot_seed: 5000.0,
  jackpot_increment: 0.25,
  winner_selection_mode: "guaranteed_winner",
  pool_reset_rule: "reset_to_seed",
  max_jackpot: 50000.0,
  is_active: true,
  created_by: "System"
)

# Weekly Mega Game (similar to Powerball/Mega Millions)
weekly_game = LotteryGame.create!(
  name: "Mega Weekly",
  description: "Big jackpot weekly draws! Pick 5 numbers from 1-70 plus a Mega Ball from 1-25.",
  game_type: "weekly",
  draw_frequency: 10080, # 7 days (10080 minutes)
  ticket_price: 3.00,
  numbers_to_pick: 5,
  number_range_min: 1,
  number_range_max: 70,
  bonus_ball: true,
  bonus_range_min: 1,
  bonus_range_max: 25,
  multiplier_available: true,
  multiplier_cost: 1.00,
  prize_pool_percentage: 50.0,
  jackpot_seed: 1000000.0,
  jackpot_increment: 0.35,
  winner_selection_mode: "traditional",
  pool_reset_rule: "carry_forward",
  max_jackpot: 100000000.0,
  is_active: true,
  created_by: "System"
)

# Progressive Accumulator Game
progressive_game = LotteryGame.create!(
  name: "Progressive Millions",
  description: "Growing jackpot that never resets! Pick 6 numbers from 1-59.",
  game_type: "progressive",
  draw_frequency: 4320, # 3 days (4320 minutes)
  ticket_price: 10.00,
  numbers_to_pick: 6,
  number_range_min: 1,
  number_range_max: 59,
  bonus_ball: false,
  multiplier_available: true,
  multiplier_cost: 5.00,
  prize_pool_percentage: 70.0,
  jackpot_seed: 5000000.0,
  jackpot_increment: 0.50,
  winner_selection_mode: "traditional",
  pool_reset_rule: "never_reset",
  max_jackpot: 500000000.0,
  is_active: true,
  created_by: "System"
)

puts "✓ Lightning 5 (Rapid - 5 min draws) - $#{rapid_game.current_jackpot}"
puts "✓ Power Hour (Hourly draws) - $#{hourly_game.current_jackpot}"
puts "✓ Daily Numbers (Daily draws) - $#{daily_game.current_jackpot}"
puts "✓ Mega Weekly (Weekly draws) - $#{weekly_game.current_jackpot}"
puts "✓ Progressive Millions (3-day draws) - $#{progressive_game.current_jackpot}"

puts "\nLottery games created successfully!"
puts "Active games: #{LotteryGame.active.count}"
puts "Total prize pools: $#{LotteryGame.active.sum(:current_jackpot)}"
