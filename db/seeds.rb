# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🎰 Seeding American Lottery Platform Database..."
puts "=" * 50

# ============================================================================
# 1. STATE JURISDICTIONS - US Lottery Legal Framework
# ============================================================================
puts "📍 Creating State Jurisdictions..."

state_jurisdictions_data = [
  # Legal Lottery States
  {
    state_code: 'CA', state_name: 'California', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.133, winnings_threshold: 600, claim_period: 180,
    special_rules: 'Must claim prizes over $600 in person. Lottery winnings subject to state income tax.'
  },
  {
    state_code: 'NY', state_name: 'New York', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0882, winnings_threshold: 5000, claim_period: 365,
    special_rules: 'Winners have one year to claim prizes. State tax applies to winnings over $5,000.'
  },
  {
    state_code: 'FL', state_name: 'Florida', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 600, claim_period: 180,
    special_rules: 'No state income tax on lottery winnings. Must claim within 180 days.'
  },
  {
    state_code: 'TX', state_name: 'Texas', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 600, claim_period: 180,
    special_rules: 'No state income tax. Prizes over $600 require identity verification.'
  },
  {
    state_code: 'PA', state_name: 'Pennsylvania', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0307, winnings_threshold: 5000, claim_period: 365,
    special_rules: 'State tax rate of 3.07%. Winners must claim within one year.'
  },
  {
    state_code: 'OH', state_name: 'Ohio', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0399, winnings_threshold: 600, claim_period: 180,
    special_rules: 'State income tax applies to all winnings over $600.'
  },
  {
    state_code: 'IL', state_name: 'Illinois', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0495, winnings_threshold: 1000, claim_period: 365,
    special_rules: 'State tax on winnings over $1,000. One year claim period.'
  },
  {
    state_code: 'GA', state_name: 'Georgia', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0575, winnings_threshold: 5000, claim_period: 180,
    special_rules: 'State tax applies to winnings over $5,000. 180-day claim period.'
  },
  {
    state_code: 'NC', state_name: 'North Carolina', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.055, winnings_threshold: 600, claim_period: 180,
    special_rules: 'State tax rate of 5.5%. Must claim prizes within 180 days.'
  },
  {
    state_code: 'MI', state_name: 'Michigan', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0425, winnings_threshold: 600, claim_period: 365,
    special_rules: 'State income tax of 4.25%. One year to claim prizes.'
  },
  {
    state_code: 'NJ', state_name: 'New Jersey', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.1075, winnings_threshold: 10000, claim_period: 365,
    special_rules: 'Highest state tax rate at 10.75%. Must claim within one year.'
  },
  {
    state_code: 'VA', state_name: 'Virginia', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0575, winnings_threshold: 600, claim_period: 180,
    special_rules: 'State tax of 5.75%. 180-day claim period for all prizes.'
  },
  {
    state_code: 'WA', state_name: 'Washington', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 600, claim_period: 180,
    special_rules: 'No state income tax on lottery winnings. 180-day claim period.'
  },
  {
    state_code: 'AZ', state_name: 'Arizona', lottery_legal: true, minimum_age: 21,
    tax_rate: 0.025, winnings_threshold: 600, claim_period: 180,
    special_rules: 'Minimum age 21. State tax of 2.5% on winnings.'
  },
  {
    state_code: 'MA', state_name: 'Massachusetts', lottery_legal: true, minimum_age: 18,
    tax_rate: 0.05, winnings_threshold: 600, claim_period: 365,
    special_rules: 'State tax of 5%. One year claim period for all prizes.'
  },

  # Prohibited States
  {
    state_code: 'AL', state_name: 'Alabama', lottery_legal: false, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 0, claim_period: 0,
    special_rules: 'Lottery gambling is prohibited by state law.'
  },
  {
    state_code: 'UT', state_name: 'Utah', lottery_legal: false, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 0, claim_period: 0,
    special_rules: 'All forms of gambling prohibited by state constitution.'
  },
  {
    state_code: 'HI', state_name: 'Hawaii', lottery_legal: false, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 0, claim_period: 0,
    special_rules: 'Lottery and gambling prohibited by state law.'
  },
  {
    state_code: 'NV', state_name: 'Nevada', lottery_legal: false, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 0, claim_period: 0,
    special_rules: 'No state lottery due to casino gaming monopoly.'
  },
  {
    state_code: 'WY', state_name: 'Wyoming', lottery_legal: false, minimum_age: 18,
    tax_rate: 0.0, winnings_threshold: 0, claim_period: 0,
    special_rules: 'Lottery prohibited, only participates in multi-state games.'
  }
]

state_jurisdictions_data.each do |jurisdiction_data|
  jurisdiction = StateJurisdiction.find_or_create_by(state_code: jurisdiction_data[:state_code]) do |sj|
    sj.assign_attributes(jurisdiction_data)
  end

  if jurisdiction.persisted?
    puts "✅ #{jurisdiction.state_name} (#{jurisdiction.state_code}) - #{jurisdiction.lottery_legal? ? 'Legal' : 'Prohibited'}"
  else
    puts "❌ Failed to create #{jurisdiction_data[:state_name]}: #{jurisdiction.errors.full_messages.join(', ')}"
  end
end

# ============================================================================
# 2. ADMIN USER
# ============================================================================
puts "\n👤 Creating Admin User..."

if User.where(role: :super_admin).count.zero?
  admin = User.new(
    email: 'admin@alot-lottery.com',
    password: 'Admin123!',
    password_confirmation: 'Admin123!',
    name: 'System Administrator',
    username: 'admin',
    role: :super_admin,
    account_balance: 0.0,
    state_jurisdiction: StateJurisdiction.find_by(state_code: 'CA')
  )

  if admin.save
    puts "✅ Admin user created successfully!"
    puts "   Email: admin@alot-lottery.com"
    puts "   Password: Admin123!"
    puts "   ⚠️  IMPORTANT: Change this password after first login!"
  else
    puts "❌ Failed to create admin user: #{admin.errors.full_messages.join(', ')}"
  end
else
  puts "✅ Admin user already exists, skipping creation."
end

# ============================================================================
# 3. SAMPLE USERS FOR DEVELOPMENT
# ============================================================================
puts "\n👥 Creating Sample Users..."

sample_users_data = [
  {
    email: 'john.doe@example.com', name: 'John Doe', username: 'johndoe',
    state: 'CA', balance: 250.00, role: :player
  },
  {
    email: 'jane.smith@example.com', name: 'Jane Smith', username: 'janesmith',
    state: 'NY', balance: 150.00, role: :player
  },
  {
    email: 'mike.johnson@example.com', name: 'Mike Johnson', username: 'mikej',
    state: 'FL', balance: 500.00, role: :player
  },
  {
    email: 'sarah.wilson@example.com', name: 'Sarah Wilson', username: 'sarahw',
    state: 'TX', balance: 75.00, role: :player
  },
  {
    email: 'david.brown@example.com', name: 'David Brown', username: 'davidb',
    state: 'PA', balance: 300.00, role: :player
  }
]

sample_users_data.each do |user_data|
  next if User.find_by(email: user_data[:email])

  state_jurisdiction = StateJurisdiction.find_by(state_code: user_data[:state])

  user = User.new(
    email: user_data[:email],
    password: 'Password123!',
    password_confirmation: 'Password123!',
    name: user_data[:name],
    username: user_data[:username],
    role: user_data[:role],
    account_balance: user_data[:balance],
    state_jurisdiction: state_jurisdiction
  )

  if user.save
    puts "✅ Created user: #{user.name} (#{user.email}) - $#{user.account_balance}"
  else
    puts "❌ Failed to create user #{user_data[:name]}: #{user.errors.full_messages.join(', ')}"
  end
end

# ============================================================================
# 4. LOTTERY GAMES - Realistic American Lottery Games
# ============================================================================
puts "\n🎲 Creating Lottery Games..."

lottery_games_data = [
  {
    name: 'Lightning 5', game_type: 'rapid', description: 'Fast-paced 5-number game with draws every 5 minutes',
    ticket_price: 2.00, number_range_max: 39, numbers_to_pick: 5, bonus_ball: false,
    draw_frequency: 5, current_jackpot: 50000.00, is_active: true,
    jackpot_seed: 10000.00, prize_pool_percentage: 60.0, number_range_min: 1,
    jackpot_increment: 0.1, multiplier_available: true, multiplier_cost: 1.0,
    pool_reset_rule: 'reset_to_seed', max_jackpot: 100000.00, created_by: 'System',
    winner_selection_mode: 'guaranteed_winner'
  },
  {
    name: 'Power Hour', game_type: 'hourly', description: 'Hourly draws with growing jackpots',
    ticket_price: 3.00, number_range_max: 49, numbers_to_pick: 5, bonus_ball: true,
    draw_frequency: 60, current_jackpot: 250000.00, is_active: true,
    jackpot_seed: 50000.00, prize_pool_percentage: 65.0, number_range_min: 1,
    jackpot_increment: 0.15, multiplier_available: true, multiplier_cost: 2.0,
    pool_reset_rule: 'carry_forward', max_jackpot: 500000.00, created_by: 'System',
    winner_selection_mode: 'guaranteed_winner'
  },
  {
    name: 'Daily Numbers', game_type: 'daily', description: 'Classic daily lottery with consistent prizes',
    ticket_price: 1.00, number_range_max: 35, numbers_to_pick: 6, bonus_ball: false,
    draw_frequency: 1440, current_jackpot: 100000.00, is_active: true,
    jackpot_seed: 25000.00, prize_pool_percentage: 55.0, number_range_min: 1,
    jackpot_increment: 0.05, multiplier_available: false, multiplier_cost: 0.0,
    pool_reset_rule: 'reset_to_seed', max_jackpot: 200000.00, created_by: 'System',
    winner_selection_mode: 'guaranteed_winner'
  },
  {
    name: 'Mega Weekly', game_type: 'weekly', description: 'Weekly mega jackpot with life-changing prizes',
    ticket_price: 5.00, number_range_max: 70, numbers_to_pick: 5, bonus_ball: true,
    draw_frequency: 10080, current_jackpot: 2500000.00, is_active: true,
    jackpot_seed: 500000.00, prize_pool_percentage: 70.0, number_range_min: 1,
    jackpot_increment: 0.25, multiplier_available: true, multiplier_cost: 3.0,
    pool_reset_rule: 'never_reset', max_jackpot: 10000000.00, created_by: 'System',
    winner_selection_mode: 'random_selection'
  },
  {
    name: 'Progressive Millions', game_type: 'progressive', description: 'Multi-state progressive jackpot game',
    ticket_price: 3.00, number_range_max: 59, numbers_to_pick: 5, bonus_ball: true,
    draw_frequency: 4320, current_jackpot: 15000000.00, is_active: true,
    jackpot_seed: 1000000.00, prize_pool_percentage: 75.0, number_range_min: 1,
    jackpot_increment: 0.3, multiplier_available: true, multiplier_cost: 2.0,
    pool_reset_rule: 'never_reset', max_jackpot: 50000000.00, created_by: 'System',
    winner_selection_mode: 'random_selection'
  },
  {
    name: 'Lucky 7s', game_type: 'daily', description: 'Simple 3-number game with daily draws',
    ticket_price: 1.00, number_range_max: 9, numbers_to_pick: 3, bonus_ball: false,
    draw_frequency: 1440, current_jackpot: 5000.00, is_active: true,
    jackpot_seed: 1000.00, prize_pool_percentage: 50.0, number_range_min: 1,
    jackpot_increment: 0.05, multiplier_available: false, multiplier_cost: 0.0,
    pool_reset_rule: 'reset_to_seed', max_jackpot: 25000.00, created_by: 'System',
    winner_selection_mode: 'guaranteed_winner'
  }
]

lottery_games_data.each do |game_data|
  game = LotteryGame.find_or_create_by(name: game_data[:name]) do |lg|
    lg.assign_attributes(game_data)
  end

  if game.persisted?
    puts "✅ #{game.name} - $#{game.ticket_price} tickets, $#{game.current_jackpot.to_i} jackpot"
  else
    puts "❌ Failed to create #{game_data[:name]}: #{game.errors.full_messages.join(', ')}"
  end
end

# ============================================================================
# 5. INSTANT GAMES - Digital Scratch-Off Games
# ============================================================================
puts "\n🎫 Creating Instant Games..."

instant_games_data = [
  {
    name: 'Lucky Stars', ticket_price: 1.00, total_tickets: 100000, remaining_tickets: 95000,
    top_prize: 10000, is_active: true, overall_odds: '1 in 3.5',
    prize_structure: {
      '10000' => 1, '1000' => 10, '500' => 25, '100' => 100, '50' => 500,
      '25' => 1000, '10' => 2500, '5' => 5000, '2' => 10000, '1' => 15000
    },
    description: 'Match three stars to win! Top prize $10,000!'
  },
  {
    name: 'Cash Explosion', ticket_price: 5.00, total_tickets: 50000, remaining_tickets: 47500,
    top_prize: 100000, is_active: true, overall_odds: '1 in 4.2',
    prize_structure: {
      '100000' => 1, '10000' => 5, '5000' => 10, '1000' => 50, '500' => 100,
      '250' => 200, '100' => 500, '50' => 1000, '25' => 2000, '10' => 3000, '5' => 5000
    },
    description: 'Explosive cash prizes! Win up to $100,000 instantly!'
  },
  {
    name: 'Diamond Riches', ticket_price: 10.00, total_tickets: 25000, remaining_tickets: 23750,
    top_prize: 250000, is_active: true, overall_odds: '1 in 3.8',
    prize_structure: {
      '250000' => 1, '25000' => 2, '10000' => 5, '5000' => 15, '2500' => 25,
      '1000' => 50, '500' => 100, '250' => 200, '100' => 500, '50' => 750, '25' => 1000, '10' => 1500
    },
    description: 'Discover sparkling diamond prizes worth up to $250,000!'
  },
  {
    name: 'Millionaire Club', ticket_price: 20.00, total_tickets: 10000, remaining_tickets: 9800,
    top_prize: 1000000, is_active: true, overall_odds: '1 in 2.9',
    prize_structure: {
      '1000000' => 1, '100000' => 2, '50000' => 3, '25000' => 5, '10000' => 10,
      '5000' => 20, '2500' => 30, '1000' => 50, '500' => 100, '250' => 200, '100' => 300, '50' => 400, '20' => 500
    },
    description: 'Join the millionaire club! Win up to $1,000,000!'
  },
  {
    name: 'Holiday Jackpot', ticket_price: 3.00, total_tickets: 30000, remaining_tickets: 28500,
    top_prize: 50000, is_active: true, overall_odds: '1 in 3.1',
    prize_structure: {
      '50000' => 1, '5000' => 5, '2500' => 10, '1000' => 25, '500' => 50,
      '250' => 100, '100' => 250, '50' => 500, '25' => 1000, '15' => 1500, '10' => 2000, '5' => 3000, '3' => 4000
    },
    description: 'Holiday magic with festive prizes up to $50,000!'
  },
  {
    name: 'Quick Cash', ticket_price: 2.00, total_tickets: 75000, remaining_tickets: 71250,
    top_prize: 25000, is_active: true, overall_odds: '1 in 3.6',
    prize_structure: {
      '25000' => 1, '2500' => 5, '1000' => 15, '500' => 30, '250' => 75,
      '100' => 150, '50' => 300, '25' => 750, '20' => 1000, '10' => 2500, '5' => 4000, '2' => 6000
    },
    description: 'Quick and easy cash prizes! Win up to $25,000!'
  }
]

instant_games_data.each do |game_data|
  game = InstantGame.find_or_create_by(name: game_data[:name]) do |ig|
    ig.assign_attributes(game_data)
  end

  if game.persisted?
    puts "✅ #{game.name} - $#{game.ticket_price} tickets, $#{game.top_prize.to_i} top prize (#{game.remaining_tickets} remaining)"
  else
    puts "❌ Failed to create #{game_data[:name]}: #{game.errors.full_messages.join(', ')}"
  end
end

# ============================================================================
# 6. SAMPLE TICKETS AND DRAWS FOR DEVELOPMENT
# ============================================================================
puts "\n🎫 Creating Sample Tickets and Draws..."

# Get sample users and games for creating realistic data
sample_users = User.where(role: :player).limit(5)
lottery_games = LotteryGame.all
instant_games = InstantGame.all

if sample_users.any? && lottery_games.any?
  # Create some recent draws with results
  lottery_games.each do |game|
    # Create a completed draw from yesterday
    draw = Draw.find_or_create_by(
      lottery_game: game,
      draw_date: 1.day.ago,
      status: 'completed'
    ) do |d|
      # Generate realistic winning numbers
      winning_numbers = (1..game.numbers_to_pick).map { rand(game.number_range_min..game.number_range_max) }.sort

      d.winning_numbers = winning_numbers
      d.jackpot_amount = game.current_jackpot
    end

    if draw.persisted?
      puts "✅ Created draw for #{game.name} - Numbers: #{draw.winning_numbers.join(', ')}"
    end
  end

  # Create sample tickets for users
  sample_users.each do |user|
    # Create 3-5 lottery tickets per user
    rand(3..5).times do
      game = lottery_games.sample

      # Generate random numbers for the ticket
      selected_numbers = (1..game.numbers_to_pick).map { rand(game.number_range_min..game.number_range_max) }.sort

      ticket = Ticket.create(
        user: user,
        lottery_game: game,
        numbers: selected_numbers,
        cost: game.ticket_price,
        purchase_date: rand(7.days).seconds.ago,
        status: [ 'pending', 'active', 'won' ].sample
      )

      # Randomly make some tickets winners
      if rand(1..100) <= 5 # 5% chance of winning
        ticket.update(
          status: 'won',
          prize_amount: [ game.ticket_price * 2, game.ticket_price * 5, game.ticket_price * 10 ].sample
        )
      end
    end

    # Create 2-3 scratch-off tickets per user
    rand(2..3).times do
      game = instant_games.sample

      scratch_off = ScratchOff.create(
        user: user,
        instant_game: game,
        ticket_number: "#{game.name.upcase.gsub(' ', '')}-#{SecureRandom.hex(4).upcase}",
        purchase_date: rand(30.days).seconds.ago,
        is_scratched: [ true, false ].sample,
        is_winner: [ true, false ].sample
      )

      # If scratched and winner, set prize amount
      if scratch_off.is_scratched && scratch_off.is_winner
        prize_structure = game.prize_structure.is_a?(String) ? JSON.parse(game.prize_structure) : game.prize_structure
        prize_amounts = prize_structure.keys.map(&:to_f).sort
        # Select a random prize amount, biased toward smaller prizes
        if prize_amounts.any?
          mid_point = [ prize_amounts.length / 2, 0 ].max
          prize_amount = prize_amounts[rand(mid_point..prize_amounts.length-1)]
          scratch_off.update(prize_amount: prize_amount, is_claimed: [ true, false ].sample)
        end
      end

      # Set scratch date if scratched
      if scratch_off.is_scratched
        scratch_off.update(scratch_date: scratch_off.purchase_date + rand(1..24).hours)
      end
    end

    puts "✅ Created sample tickets for #{user.name}"
  end

  # Create some active subscriptions
  sample_users.first(3).each do |user|
    game = lottery_games.sample

    subscription = Subscription.create(
      user: user,
      lottery_game: game,
      frequency: [ 'weekly', 'bi_weekly', 'monthly' ].sample,
      auto_renew: [ true, false ].sample,
      next_purchase_date: rand(1..7).days.from_now,
      status: 'active'
    )

    if subscription.persisted?
      puts "✅ Created subscription for #{user.name} - #{game.name}"
    end
  end

  puts "✅ Sample tickets, draws, and subscriptions created successfully!"
else
  puts "⚠️  Skipping sample tickets - no users or games found"
end

# ============================================================================
# 7. FINAL STATISTICS AND SUMMARY
# ============================================================================
puts "\n📊 Database Seeding Complete!"
puts "=" * 50

# Display summary statistics
states_count = StateJurisdiction.count
legal_states = StateJurisdiction.where(lottery_legal: true).count
users_count = User.count
admin_count = User.where(role: :super_admin).count
player_count = User.where(role: :player).count
lottery_games_count = LotteryGame.count
instant_games_count = InstantGame.count
tickets_count = Ticket.count
winning_tickets = Ticket.where(status: 'won').count
scratch_offs_count = ScratchOff.count
winning_scratch_offs = ScratchOff.where(is_winner: true).count
subscriptions_count = Subscription.count
draws_count = Draw.count

puts "📍 State Jurisdictions: #{states_count} total (#{legal_states} legal, #{states_count - legal_states} prohibited)"
puts "👤 Users: #{users_count} total (#{admin_count} admin, #{player_count} players)"
puts "🎲 Lottery Games: #{lottery_games_count} active games"
puts "🎫 Instant Games: #{instant_games_count} scratch-off games"
puts "🎫 Tickets: #{tickets_count} total (#{winning_tickets} winners)"
puts "🎫 Scratch-Offs: #{scratch_offs_count} total (#{winning_scratch_offs} winners)"
puts "🔄 Subscriptions: #{subscriptions_count} active"
puts "🎯 Draws: #{draws_count} completed"

total_jackpots = LotteryGame.sum(:current_jackpot)
total_instant_prizes = InstantGame.sum(:top_prize)

puts "\n💰 Prize Pool Summary:"
puts "   Lottery Jackpots: $#{total_jackpots.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "   Instant Game Prizes: $#{total_instant_prizes.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "   Combined Prize Pool: $#{(total_jackpots + total_instant_prizes).to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"

puts "\n✅ American Lottery Platform ready for development!"
puts "🚀 Start the server with: bin/rails server"
puts "🔑 Admin login: admin@alot-lottery.com / Admin123!"
puts "👥 Sample user login: john.doe@example.com / Password123!"
