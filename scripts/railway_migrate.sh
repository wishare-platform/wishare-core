#!/bin/bash

# Railway Migration Script - Run this to ensure all migrations are applied
# Usage: railway run ./scripts/railway_migrate.sh

echo "========================================"
echo "WISHARE RAILWAY MIGRATION CHECK"
echo "========================================"

echo ""
echo "1. Checking migration status..."
bundle exec rails db:migrate:status

echo ""
echo "2. Running pending migrations..."
bundle exec rails db:migrate

echo ""
echo "3. Verifying essential tables..."
bundle exec rails runner "
puts 'Checking essential tables...'
essential_tables = ['users', 'activity_feeds', 'user_interactions', 'wishlists', 'wishlist_items', 'connections']
essential_tables.each do |table|
  if ActiveRecord::Base.connection.table_exists?(table)
    puts \"✅ #{table}: EXISTS\"
  else
    puts \"❌ #{table}: MISSING\"
  end
end
"

echo ""
echo "4. Creating sample activity if needed..."
bundle exec rails runner "
user_count = User.count
puts \"Total users: #{user_count}\"

if user_count == 0
  puts 'No users found - creating admin user for testing'
  admin = User.create!(
    email: 'admin@wishare.xyz',
    password: 'wishare123!',
    name: 'Admin User',
    confirmed_at: Time.current
  )
  puts \"Created admin user: #{admin.email}\"
end
"

echo ""
echo "Migration check complete!"
echo "========================================"