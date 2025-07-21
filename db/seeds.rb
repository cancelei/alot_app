# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create initial admin user if none exists
puts "Creating initial admin user..."

# Check if we already have a super_admin
if User.where(role: :super_admin).count.zero?
  admin = User.new(
    email: 'admin@alot-lottery.com',
    password: 'Admin123!',  # This should be changed immediately after first login
    password_confirmation: 'Admin123!',
    name: 'System Administrator',
    role: :super_admin
  )

  if admin.save
    puts "✅ Admin user created successfully!"
    puts "Email: admin@alot-lottery.com"
    puts "Password: Admin123!"
    puts "⚠️  IMPORTANT: Please change this password immediately after first login!"
  else
    puts "❌ Failed to create admin user: #{admin.errors.full_messages.join(', ')}"
  end
else
  puts "✅ Admin user already exists, skipping creation."
end

# Additional seed data can be added below
