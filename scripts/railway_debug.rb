#!/usr/bin/env ruby

# Railway Debug Script - Run this in Railway console to diagnose issues
# Usage: railway run bundle exec ruby scripts/railway_debug.rb

puts "=" * 80
puts "WISHARE RAILWAY PRODUCTION DEBUGGING"
puts "=" * 80

begin
  # 1. Database Connection Test
  puts "\n1. DATABASE CONNECTION TEST"
  puts "-" * 40

  ActiveRecord::Base.connection.execute("SELECT 1")
  puts "✅ Database connection: SUCCESS"

  # 2. Essential Tables Check
  puts "\n2. ESSENTIAL TABLES CHECK"
  puts "-" * 40

  essential_tables = [
    'users', 'activity_feeds', 'user_interactions',
    'wishlists', 'wishlist_items', 'connections',
    'schema_migrations'
  ]

  essential_tables.each do |table|
    if ActiveRecord::Base.connection.table_exists?(table)
      count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
      puts "✅ #{table}: EXISTS (#{count} records)"
    else
      puts "❌ #{table}: MISSING"
    end
  end

  # 3. Migration Status
  puts "\n3. MIGRATION STATUS"
  puts "-" * 40

  latest_migration = ActiveRecord::SchemaMigration.maximum(:version)
  puts "📋 Latest migration: #{latest_migration}"

  pending_migrations = ActiveRecord::Base.connection.migration_context.needs_migration?
  if pending_migrations
    puts "⚠️  PENDING MIGRATIONS DETECTED"
  else
    puts "✅ All migrations applied"
  end

  # 4. Environment Variables Check
  puts "\n4. ENVIRONMENT VARIABLES CHECK"
  puts "-" * 40

  critical_env_vars = [
    'DATABASE_URL', 'SECRET_KEY_BASE', 'HOST_URL',
    'GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET',
    'SENDGRID_API_KEY', 'JWT_SECRET_KEY'
  ]

  critical_env_vars.each do |var|
    if ENV[var].present?
      puts "✅ #{var}: SET"
    else
      puts "❌ #{var}: MISSING"
    end
  end

  # 5. User Data Check
  puts "\n5. USER DATA CHECK"
  puts "-" * 40

  user_count = User.count
  puts "👥 Total users: #{user_count}"

  if user_count > 0
    sample_user = User.first
    puts "📋 Sample user ID: #{sample_user.id}"
    puts "📋 Sample user email: #{sample_user.email}"

    # Test activity feed for sample user
    begin
      activities = ActivityFeedService.get_user_activities(user: sample_user, limit: 5)
      puts "✅ ActivityFeedService: SUCCESS (#{activities.count} activities)"
    rescue => e
      puts "❌ ActivityFeedService ERROR: #{e.message}"
    end
  else
    puts "⚠️  No users found - this might cause dashboard errors"
  end

  # 6. ActionCable Configuration
  puts "\n6. ACTIONCABLE CONFIGURATION"
  puts "-" * 40

  begin
    redis_url = ENV['REDIS_URL'] || ENV['REDISCLOUD_URL']
    if redis_url.present?
      puts "✅ Redis URL configured"
    else
      puts "⚠️  Redis URL not found - ActionCable might fail"
    end
  rescue => e
    puts "❌ Redis check failed: #{e.message}"
  end

  # 7. Sample Dashboard Controller Test
  puts "\n7. DASHBOARD CONTROLLER TEST"
  puts "-" * 40

  if user_count > 0
    sample_user = User.first
    begin
      # Simulate the dashboard controller logic
      recent_activities = ActivityFeedService.get_user_activities(
        user: sample_user,
        limit: 5
      )

      friend_activities = ActivityFeedService.get_friend_activities(
        user: sample_user,
        limit: 5
      )

      activity_stats = ActivityFeedService.get_activity_stats(
        user: sample_user,
        timeframe: 'week'
      )

      puts "✅ Dashboard simulation: SUCCESS"
      puts "📋 Recent activities: #{recent_activities.count}"
      puts "📋 Friend activities: #{friend_activities.count}"
      puts "📋 Activity stats: #{activity_stats.inspect}"

    rescue => e
      puts "❌ Dashboard simulation FAILED: #{e.message}"
      puts "📋 Backtrace: #{e.backtrace.first(3).join('\n')}"
    end
  end

  puts "\n" + "=" * 80
  puts "DIAGNOSIS COMPLETE"
  puts "=" * 80

rescue => e
  puts "\n❌ CRITICAL ERROR DURING DIAGNOSIS"
  puts "Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join('\n')}"
end