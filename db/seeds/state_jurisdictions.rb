# State Jurisdictions Seed Data for American Lottery System
# Based on actual US state lottery laws and regulations

state_jurisdictions_data = [
  {
    state_code: 'CA',
    state_name: 'California',
    minimum_age: 18,
    tax_rate: 0.133, # 13.3% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'California Lottery Act compliance required. No credit card purchases allowed.'
  },
  {
    state_code: 'NY',
    state_name: 'New York',
    minimum_age: 18,
    tax_rate: 0.1082, # 10.82% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 365,
    special_rules: 'New York Gaming Commission oversight. Winners must claim at customer service centers for prizes over $600.'
  },
  {
    state_code: 'TX',
    state_name: 'Texas',
    minimum_age: 18,
    tax_rate: 0.0, # No state income tax
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Texas Lottery Commission regulated. No online sales for draw games currently.'
  },
  {
    state_code: 'FL',
    state_name: 'Florida',
    minimum_age: 18,
    tax_rate: 0.0, # No state income tax
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Florida Lottery regulated. Winners have 60 days to choose lump sum vs annuity.'
  },
  {
    state_code: 'PA',
    state_name: 'Pennsylvania',
    minimum_age: 18,
    tax_rate: 0.0307, # 3.07% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 365,
    special_rules: 'Pennsylvania Lottery regulated. Online play available for registered users.'
  },
  {
    state_code: 'IL',
    state_name: 'Illinois',
    minimum_age: 18,
    tax_rate: 0.0495, # 4.95% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 365,
    special_rules: 'Illinois Lottery regulated. Online subscriptions available.'
  },
  {
    state_code: 'OH',
    state_name: 'Ohio',
    minimum_age: 18,
    tax_rate: 0.0399, # 3.99% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Ohio Lottery Commission regulated.'
  },
  {
    state_code: 'GA',
    state_name: 'Georgia',
    minimum_age: 18,
    tax_rate: 0.0575, # 5.75% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Georgia Lottery Corporation regulated. Proceeds benefit education.'
  },
  {
    state_code: 'NC',
    state_name: 'North Carolina',
    minimum_age: 18,
    tax_rate: 0.0525, # 5.25% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'North Carolina Education Lottery regulated.'
  },
  {
    state_code: 'MI',
    state_name: 'Michigan',
    minimum_age: 18,
    tax_rate: 0.0425, # 4.25% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 365,
    special_rules: 'Michigan Lottery regulated. Online play available.'
  },
  {
    state_code: 'AZ',
    state_name: 'Arizona',
    minimum_age: 21, # Higher minimum age
    tax_rate: 0.025, # 2.5% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Arizona Lottery regulated. Must be 21 or older to play.'
  },
  {
    state_code: 'IA',
    state_name: 'Iowa',
    minimum_age: 21, # Higher minimum age
    tax_rate: 0.0853, # 8.53% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 365,
    special_rules: 'Iowa Lottery regulated. Must be 21 or older to play.'
  },
  {
    state_code: 'LA',
    state_name: 'Louisiana',
    minimum_age: 21, # Higher minimum age
    tax_rate: 0.06, # 6% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Louisiana Lottery Corporation regulated. Must be 21 or older to play.'
  },
  {
    state_code: 'NJ',
    state_name: 'New Jersey',
    minimum_age: 18,
    tax_rate: 0.1075, # 10.75% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 365,
    special_rules: 'New Jersey Lottery regulated. Online play available for residents.'
  },
  {
    state_code: 'VA',
    state_name: 'Virginia',
    minimum_age: 18,
    tax_rate: 0.0575, # 5.75% state tax rate
    lottery_legal: true,
    is_active: true,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Virginia Lottery regulated. Online play available.'
  },
  # States where lottery is not legal or restricted
  {
    state_code: 'UT',
    state_name: 'Utah',
    minimum_age: 18,
    tax_rate: 0.0495, # 4.95% state tax rate
    lottery_legal: false,
    is_active: false,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'Lottery prohibited by state constitution.'
  },
  {
    state_code: 'NV',
    state_name: 'Nevada',
    minimum_age: 21,
    tax_rate: 0.0, # No state income tax
    lottery_legal: false,
    is_active: false,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'State lottery prohibited. Casino gaming regulated separately.'
  },
  {
    state_code: 'HI',
    state_name: 'Hawaii',
    minimum_age: 18,
    tax_rate: 0.11, # 11% state tax rate
    lottery_legal: false,
    is_active: false,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'All forms of gambling prohibited by state law.'
  },
  {
    state_code: 'AL',
    state_name: 'Alabama',
    minimum_age: 18,
    tax_rate: 0.05, # 5% state tax rate
    lottery_legal: false,
    is_active: false,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'State lottery prohibited by constitution.'
  },
  {
    state_code: 'AK',
    state_name: 'Alaska',
    minimum_age: 18,
    tax_rate: 0.0, # No state income tax
    lottery_legal: false,
    is_active: false,
    winnings_threshold: 600.0,
    claim_period: 180,
    special_rules: 'No state lottery. Limited charitable gaming only.'
  }
]

puts "Creating state jurisdictions..."

state_jurisdictions_data.each do |state_data|
  state = StateJurisdiction.find_or_create_by(state_code: state_data[:state_code]) do |s|
    s.state_name = state_data[:state_name]
    s.minimum_age = state_data[:minimum_age]
    s.tax_rate = state_data[:tax_rate]
    s.lottery_legal = state_data[:lottery_legal]
    s.is_active = state_data[:is_active]
    s.winnings_threshold = state_data[:winnings_threshold]
    s.claim_period = state_data[:claim_period]
    s.special_rules = state_data[:special_rules]
  end

  puts "✓ #{state.state_name} (#{state.state_code}) - Legal: #{state.lottery_legal? ? 'Yes' : 'No'}"
end

puts "\nState jurisdictions created successfully!"
puts "Legal lottery states: #{StateJurisdiction.lottery_legal.count}"
puts "Active lottery states: #{StateJurisdiction.active.count}"
