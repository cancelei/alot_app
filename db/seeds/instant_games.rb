# Sample Instant Games (Scratch-offs) Seed Data for American Lottery System
# Creates various price point scratch-off games

puts "Creating sample instant games..."

# $1 Scratch-off Game
dollar_game = InstantGame.create!(
  name: "Lucky Stars",
  description: "Scratch to reveal three matching stars and win up to $1,000!",
  ticket_price: 1.00,
  total_tickets: 100000,
  remaining_tickets: 100000,
  top_prize: 1000.00,
  overall_odds: "1 in 4.5",
  prize_structure: {
    "1000" => { amount: 1000.00, quantity: 10, remaining: 10 },
    "500" => { amount: 500.00, quantity: 20, remaining: 20 },
    "100" => { amount: 100.00, quantity: 100, remaining: 100 },
    "50" => { amount: 50.00, quantity: 200, remaining: 200 },
    "20" => { amount: 20.00, quantity: 500, remaining: 500 },
    "10" => { amount: 10.00, quantity: 1000, remaining: 1000 },
    "5" => { amount: 5.00, quantity: 2000, remaining: 2000 },
    "2" => { amount: 2.00, quantity: 5000, remaining: 5000 },
    "1" => { amount: 1.00, quantity: 13500, remaining: 13500 }
  }.to_json,
  game_number: "001",
  launch_date: Date.current,
  end_date: Date.current + 6.months,
  second_chance_available: true,
  second_chance_description: "Enter non-winning tickets for a chance to win $10,000!",
  is_active: true
)

# $5 Scratch-off Game
five_dollar_game = InstantGame.create!(
  name: "Cash Explosion",
  description: "Explosive wins up to $50,000! Match three amounts to win that prize.",
  ticket_price: 5.00,
  total_tickets: 50000,
  remaining_tickets: 50000,
  top_prize: 50000.00,
  overall_odds: "1 in 3.8",
  prize_structure: {
    "50000" => { amount: 50000.00, quantity: 2, remaining: 2 },
    "10000" => { amount: 10000.00, quantity: 5, remaining: 5 },
    "5000" => { amount: 5000.00, quantity: 10, remaining: 10 },
    "1000" => { amount: 1000.00, quantity: 25, remaining: 25 },
    "500" => { amount: 500.00, quantity: 50, remaining: 50 },
    "100" => { amount: 100.00, quantity: 200, remaining: 200 },
    "50" => { amount: 50.00, quantity: 400, remaining: 400 },
    "25" => { amount: 25.00, quantity: 800, remaining: 800 },
    "10" => { amount: 10.00, quantity: 2000, remaining: 2000 },
    "5" => { amount: 5.00, quantity: 8500, remaining: 8500 }
  }.to_json,
  game_number: "005",
  launch_date: Date.current,
  end_date: Date.current + 8.months,
  second_chance_available: true,
  second_chance_description: "Enter any ticket for monthly drawings worth $25,000!",
  is_active: true
)

# $10 Scratch-off Game
ten_dollar_game = InstantGame.create!(
  name: "Diamond Riches",
  description: "Uncover diamonds and win up to $100,000! Premium scratch-off experience.",
  ticket_price: 10.00,
  total_tickets: 25000,
  remaining_tickets: 25000,
  top_prize: 100000.00,
  overall_odds: "1 in 3.2",
  prize_structure: {
    "100000" => { amount: 100000.00, quantity: 2, remaining: 2 },
    "25000" => { amount: 25000.00, quantity: 3, remaining: 3 },
    "10000" => { amount: 10000.00, quantity: 5, remaining: 5 },
    "5000" => { amount: 5000.00, quantity: 10, remaining: 10 },
    "1000" => { amount: 1000.00, quantity: 25, remaining: 25 },
    "500" => { amount: 500.00, quantity: 50, remaining: 50 },
    "200" => { amount: 200.00, quantity: 100, remaining: 100 },
    "100" => { amount: 100.00, quantity: 200, remaining: 200 },
    "50" => { amount: 50.00, quantity: 500, remaining: 500 },
    "25" => { amount: 25.00, quantity: 1000, remaining: 1000 },
    "20" => { amount: 20.00, quantity: 1500, remaining: 1500 },
    "10" => { amount: 10.00, quantity: 5500, remaining: 5500 }
  }.to_json,
  game_number: "010",
  launch_date: Date.current,
  end_date: Date.current + 12.months,
  second_chance_available: true,
  second_chance_description: "Diamond Club members get exclusive second-chance drawings!",
  is_active: true
)

# $20 Premium Game
twenty_dollar_game = InstantGame.create!(
  name: "Millionaire's Club",
  description: "The ultimate scratch experience! Win up to $1,000,000 instantly!",
  ticket_price: 20.00,
  total_tickets: 10000,
  remaining_tickets: 10000,
  top_prize: 1000000.00,
  overall_odds: "1 in 2.8",
  prize_structure: {
    "1000000" => { amount: 1000000.00, quantity: 1, remaining: 1 },
    "100000" => { amount: 100000.00, quantity: 2, remaining: 2 },
    "50000" => { amount: 50000.00, quantity: 3, remaining: 3 },
    "25000" => { amount: 25000.00, quantity: 5, remaining: 5 },
    "10000" => { amount: 10000.00, quantity: 10, remaining: 10 },
    "5000" => { amount: 5000.00, quantity: 15, remaining: 15 },
    "1000" => { amount: 1000.00, quantity: 50, remaining: 50 },
    "500" => { amount: 500.00, quantity: 100, remaining: 100 },
    "200" => { amount: 200.00, quantity: 200, remaining: 200 },
    "100" => { amount: 100.00, quantity: 400, remaining: 400 },
    "50" => { amount: 50.00, quantity: 800, remaining: 800 },
    "40" => { amount: 40.00, quantity: 1000, remaining: 1000 },
    "20" => { amount: 20.00, quantity: 2500, remaining: 2500 }
  }.to_json,
  game_number: "020",
  launch_date: Date.current,
  end_date: Date.current + 18.months,
  second_chance_available: true,
  second_chance_description: "VIP second-chance drawings with luxury prizes and cash!",
  is_active: true
)

# Holiday Special Game
holiday_game = InstantGame.create!(
  name: "Holiday Jackpot",
  description: "Limited-time holiday special! Festive fun with amazing prizes up to $25,000!",
  ticket_price: 3.00,
  total_tickets: 30000,
  remaining_tickets: 30000,
  top_prize: 25000.00,
  overall_odds: "1 in 4.2",
  prize_structure: {
    "25000" => { amount: 25000.00, quantity: 3, remaining: 3 },
    "5000" => { amount: 5000.00, quantity: 5, remaining: 5 },
    "1000" => { amount: 1000.00, quantity: 15, remaining: 15 },
    "500" => { amount: 500.00, quantity: 30, remaining: 30 },
    "100" => { amount: 100.00, quantity: 150, remaining: 150 },
    "50" => { amount: 50.00, quantity: 300, remaining: 300 },
    "25" => { amount: 25.00, quantity: 600, remaining: 600 },
    "15" => { amount: 15.00, quantity: 1000, remaining: 1000 },
    "10" => { amount: 10.00, quantity: 2000, remaining: 2000 },
    "6" => { amount: 6.00, quantity: 3000, remaining: 3000 },
    "3" => { amount: 3.00, quantity: 5000, remaining: 5000 }
  }.to_json,
  game_number: "099",
  launch_date: Date.current,
  end_date: Date.current + 3.months,
  second_chance_available: true,
  second_chance_description: "Holiday second-chance drawing for a $50,000 grand prize!",
  is_active: true
)

puts "✓ Lucky Stars ($1) - #{dollar_game.remaining_tickets} tickets remaining"
puts "✓ Cash Explosion ($5) - #{five_dollar_game.remaining_tickets} tickets remaining"
puts "✓ Diamond Riches ($10) - #{ten_dollar_game.remaining_tickets} tickets remaining"
puts "✓ Millionaire's Club ($20) - #{twenty_dollar_game.remaining_tickets} tickets remaining"
puts "✓ Holiday Jackpot ($3) - #{holiday_game.remaining_tickets} tickets remaining"

puts "\nInstant games created successfully!"
puts "Active instant games: #{InstantGame.active.count}"
puts "Total tickets available: #{InstantGame.active.sum(:remaining_tickets)}"
puts "Combined top prizes: $#{InstantGame.active.sum(:top_prize)}"
