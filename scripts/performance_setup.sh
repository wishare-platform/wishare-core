#!/bin/bash
# Wishare Performance Optimization Setup Script
# Usage: ./scripts/performance_setup.sh

set -e

echo "🚀 Wishare Performance Optimization Setup"
echo "========================================"

# Check if we're in the Rails root directory
if [ ! -f "Gemfile" ] || [ ! -f "config/application.rb" ]; then
    echo "❌ Error: Please run this script from the Rails application root directory"
    exit 1
fi

echo "📋 Step 1: Adding performance monitoring gems..."

# Add gems if not already present
if ! grep -q "gem 'bullet'" Gemfile; then
    echo "  Adding bullet gem for N+1 query detection..."
    sed -i '' '/group :development, :test do/a\
  gem '\''bullet'\''
' Gemfile
fi

if ! grep -q "gem 'redis'" Gemfile; then
    echo "  Adding Redis gems for caching..."
    cat >> Gemfile << 'EOF'

# Performance optimizations
gem 'redis', '~> 5.0'
gem 'hiredis', '~> 0.6'
gem 'sidekiq', '~> 7.0'

group :development do
  gem 'rack-mini-profiler'
  gem 'memory_profiler'
  gem 'benchmark-ips'
end
EOF
fi

echo "📦 Step 2: Installing gems..."
bundle install

echo "🗄️ Step 3: Setting up database indexes..."

# Create the performance indexes migration
cat > db/migrate/$(date +%Y%m%d%H%M%S)_add_critical_performance_indexes.rb << 'EOF'
class AddCriticalPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Wishlist performance indexes
    add_index :wishlists, [:user_id, :visibility, :updated_at],
              name: 'index_wishlists_user_visibility_time',
              comment: 'Optimizes wishlist filtering by user and visibility'

    add_index :wishlists, [:visibility, :event_type, :event_date],
              name: 'index_wishlists_visibility_event',
              comment: 'Optimizes public wishlist discovery and event filtering'

    add_index :wishlists, [:event_date, :event_type],
              name: 'index_wishlists_event_calendar',
              comment: 'Optimizes upcoming/past event queries'

    # Wishlist items performance indexes
    add_index :wishlist_items, [:wishlist_id, :status, :created_at],
              name: 'index_wishlist_items_status_time',
              comment: 'Optimizes item listing with status filtering'

    add_index :wishlist_items, [:price, :currency, :created_at],
              name: 'index_wishlist_items_price_trending',
              comment: 'Optimizes trending items and price-based discovery'

    add_index :wishlist_items, [:purchased_by_id, :purchased_at],
              name: 'index_wishlist_items_purchase_tracking',
              comment: 'Optimizes purchase history and gift tracking'

    # User analytics optimization
    add_index :users, [:created_at, :role],
              name: 'index_users_registration_analytics',
              comment: 'Optimizes user growth analytics'
  end
end
EOF

echo "  Running database migration..."
bundle exec rails db:migrate

echo "⚙️ Step 4: Creating configuration files..."

# Bullet configuration
mkdir -p config/initializers
cat > config/initializers/bullet.rb << 'EOF'
if Rails.env.development?
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true
      Bullet.console = true
      Bullet.rails_logger = true
      Bullet.bullet_logger = true
      Bullet.add_footer = true

      # Whitelist known false positives
      Bullet.add_safelist type: :n_plus_one_query, class_name: "User", association: :avatar
    end
  end
end

if Rails.env.test?
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true
      Bullet.raise = true
    end
  end
end
EOF

# Redis configuration
cat > config/initializers/redis.rb << 'EOF'
if Rails.env.production?
  Redis.current = Redis.new(url: ENV['REDIS_URL'])
elsif Rails.env.development? || Rails.env.test?
  Redis.current = Redis.new(url: 'redis://localhost:6379/1')
end
EOF

# Sidekiq configuration
cat > config/initializers/sidekiq.rb << 'EOF'
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
end

# Set ActiveJob adapter
Rails.application.configure do
  config.active_job.queue_adapter = :sidekiq
end
EOF

echo "🎛️ Step 5: Updating environment configurations..."

# Update development.rb for Redis caching
if ! grep -q "redis_cache_store" config/environments/development.rb; then
    cat >> config/environments/development.rb << 'EOF'

  # Redis cache store for development
  config.cache_store = :redis_cache_store, {
    url: 'redis://localhost:6379/1',
    expires_in: 30.minutes,
    namespace: 'wishare_dev'
  }
EOF
fi

# Update production.rb for Redis
if ! grep -q "redis_cache_store" config/environments/production.rb; then
    cat >> config/environments/production.rb << 'EOF'

  # Redis cache store for production
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    expires_in: 1.hour,
    namespace: 'wishare_cache',
    pool_size: 5,
    pool_timeout: 5
  }

  # ActionCable Redis adapter
  config.action_cable.adapter = :redis
  config.action_cable.url = ENV['REDIS_URL']
EOF
fi

echo "🔧 Step 6: Creating optimized service files..."

# Create optimized dashboard service
mkdir -p app/services
cat > app/services/optimized_dashboard_service.rb << 'EOF'
class OptimizedDashboardService
  class << self
    # Optimized dashboard data loading - single query approach
    def load_dashboard_data(user)
      # Get friend IDs in single query with proper includes
      friend_data = load_friend_connections(user)
      friend_ids = friend_data.map(&:id)

      # Unified wishlist loading with single complex query
      wishlists_data = load_all_wishlists_unified(user, friend_ids)

      # Cached activity stats to reduce database load
      activity_stats = cached_activity_stats(user)

      {
        user: user,
        friend_ids: friend_ids,
        user_wishlists: wishlists_data[:user_wishlists],
        connected_wishlists: wishlists_data[:connected_wishlists],
        public_wishlists: wishlists_data[:public_wishlists],
        activity_stats: activity_stats,
        load_time: Time.current
      }
    end

    private

    # Optimized friend loading - eliminate N+1 queries
    def load_friend_connections(user)
      User.joins(
        "JOIN connections ON " +
        "(connections.partner_id = users.id AND connections.user_id = #{user.id}) OR " +
        "(connections.user_id = users.id AND connections.partner_id = #{user.id})"
      ).where("connections.status = ?", 1) # accepted
       .select("users.*, connections.user_id as connection_user_id, connections.partner_id as connection_partner_id")
       .distinct
    end

    # Unified wishlist loading - single complex query instead of 3 separate ones
    def load_all_wishlists_unified(user, friend_ids)
      all_wishlists = Wishlist
        .includes(:user, wishlist_items: [:purchased_by])
        .where(
          "(user_id = ? AND visibility IN (?)) OR " +
          "(user_id IN (?) AND visibility IN (?)) OR " +
          "(visibility = ? AND user_id NOT IN (?))",
          user.id, [:private_list, :partner_only, :publicly_visible],
          friend_ids, [:partner_only, :publicly_visible],
          :publicly_visible, [user.id] + friend_ids
        )
        .order(updated_at: :desc)

      # Partition results efficiently
      user_wishlists = []
      connected_wishlists = []
      public_wishlists = []

      all_wishlists.each do |wishlist|
        if wishlist.user_id == user.id
          user_wishlists << wishlist
        elsif friend_ids.include?(wishlist.user_id)
          connected_wishlists << wishlist
        else
          public_wishlists << wishlist
        end
      end

      {
        user_wishlists: user_wishlists,
        connected_wishlists: connected_wishlists,
        public_wishlists: public_wishlists
      }
    end

    # Cached activity stats - 15 minute cache
    def cached_activity_stats(user)
      Rails.cache.fetch("activity_stats_#{user.id}_week", expires_in: 15.minutes) do
        ActivityFeedService.get_activity_stats(user: user, timeframe: 'week')
      end
    end
  end
end
EOF

echo "📊 Step 7: Creating performance monitoring..."

# Create performance monitoring service
cat > app/services/performance_monitoring_service.rb << 'EOF'
class PerformanceMonitoringService
  class << self
    def collect_metrics
      {
        database: database_metrics,
        cache: cache_metrics,
        application: application_metrics,
        timestamp: Time.current
      }
    end

    def alert_if_needed(metrics)
      alerts = []

      # Database performance alerts
      if metrics[:database][:active_connections] > 8
        alerts << "High database connections: #{metrics[:database][:active_connections]}"
      end

      # Cache performance alerts
      if metrics[:cache][:hit_rate] && metrics[:cache][:hit_rate] < 0.7
        alerts << "Cache hit rate #{(metrics[:cache][:hit_rate] * 100).round(1)}% (<70% threshold)"
      end

      Rails.logger.warn "PERFORMANCE ALERTS: #{alerts.join('; ')}" if alerts.any?
      alerts
    end

    private

    def database_metrics
      {
        active_connections: ActiveRecord::Base.connection_pool.stat[:size],
        query_cache_enabled: ActiveRecord::Base.connection.query_cache_enabled
      }
    end

    def cache_metrics
      if Rails.cache.respond_to?(:stats)
        Rails.cache.stats
      else
        { hit_rate: nil, status: 'Cache stats not available' }
      end
    end

    def application_metrics
      {
        memory_usage_mb: (`ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i / 1024.0).round(2)
      }
    end
  end
end
EOF

echo "🧪 Step 8: Creating performance tests..."

# Create performance test directory and files
mkdir -p spec/performance
cat > spec/performance/dashboard_performance_spec.rb << 'EOF'
require 'rails_helper'
require 'benchmark'

RSpec.describe "Dashboard Performance", type: :request do
  let(:user) { create(:user) }
  let!(:wishlists) { create_list(:wishlist, 5, user: user) }
  let!(:items) { wishlists.flat_map { |w| create_list(:wishlist_item, 3, wishlist: w) } }

  before { sign_in user }

  it "loads dashboard within performance budget" do
    time = Benchmark.measure do
      get root_path
    end

    expect(response).to have_http_status(:success)
    expect(time.real * 1000).to be < 200 # 200ms budget
  end

  it "uses optimized dashboard service" do
    expect(OptimizedDashboardService).to receive(:load_dashboard_data).and_call_original
    get root_path
  end
end
EOF

echo "🚀 Step 9: Creating benchmark script..."

# Create benchmark script
mkdir -p scripts
cat > scripts/performance_benchmark.rb << 'EOF'
#!/usr/bin/env ruby
require_relative '../config/environment'
require 'benchmark'

class PerformanceBenchmark
  def self.run
    puts "🚀 Wishare Performance Benchmark"
    puts "================================"

    user = User.first
    unless user
      puts "❌ No users found. Please create a user first."
      exit 1
    end

    puts "User: #{user.name} (ID: #{user.id})"
    puts "Wishlists: #{user.wishlists.count}"
    puts "Items: #{WishlistItem.joins(:wishlist).where(wishlists: { user: user }).count}"
    puts "Friends: #{user.connections.accepted.count}"
    puts

    # Test optimized dashboard loading
    puts "Testing optimized dashboard loading..."
    dashboard_time = Benchmark.measure do
      OptimizedDashboardService.load_dashboard_data(user)
    end

    puts "Dashboard load time: #{(dashboard_time.real * 1000).round(2)}ms"

    # Test activity stats caching
    puts "Testing activity stats caching..."
    stats_time = Benchmark.measure do
      ActivityFeedService.get_activity_stats(user: user, timeframe: 'week')
    end

    puts "Activity stats time: #{(stats_time.real * 1000).round(2)}ms"

    total_time = (dashboard_time.real + stats_time.real) * 1000
    puts
    puts "Total optimized time: #{total_time.round(2)}ms"

    if total_time < 150
      puts "✅ EXCELLENT: Under 150ms target"
    elsif total_time < 200
      puts "✅ GOOD: Under 200ms target"
    else
      puts "⚠️  NEEDS IMPROVEMENT: Exceeds 200ms target"
    end

    # Performance monitoring
    puts
    puts "Performance Metrics:"
    metrics = PerformanceMonitoringService.collect_metrics
    puts "  Memory usage: #{metrics[:application][:memory_usage_mb]}MB"
    puts "  Database connections: #{metrics[:database][:active_connections]}"
    puts "  Cache status: #{metrics[:cache][:status] || 'Available'}"
  end
end

PerformanceBenchmark.run
EOF

chmod +x scripts/performance_benchmark.rb

echo "📝 Step 10: Creating load test script..."

cat > scripts/load_test.sh << 'EOF'
#!/bin/bash
# Wishare Load Testing Script

echo "🔥 Wishare Load Testing"
echo "======================"

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    echo "❌ Apache Bench (ab) not found."
    echo "Install with: brew install httpd (macOS) or apt-get install apache2-utils (Ubuntu)"
    exit 1
fi

# Configuration
HOST=${1:-localhost:3000}
CONCURRENCY=${2:-5}
REQUESTS=${3:-50}

echo "Host: $HOST"
echo "Concurrency: $CONCURRENCY"
echo "Requests: $REQUESTS"
echo

# Test root path (dashboard)
echo "Testing dashboard endpoint..."
ab -n $REQUESTS -c $CONCURRENCY -g dashboard_results.tsv "http://$HOST/"

# Test wishlists index
echo "Testing wishlists index..."
ab -n $REQUESTS -c $CONCURRENCY -g wishlists_results.tsv "http://$HOST/wishlists"

echo
echo "Load test complete!"
echo "Check dashboard_results.tsv and wishlists_results.tsv for detailed results."
echo
echo "Expected performance targets:"
echo "  - Dashboard: <200ms average response time"
echo "  - Wishlists: <300ms average response time"
EOF

chmod +x scripts/load_test.sh

echo
echo "✅ Performance optimization setup complete!"
echo
echo "📋 Next Steps:"
echo "1. Run the benchmark: ruby scripts/performance_benchmark.rb"
echo "2. Start monitoring with: PerformanceMonitoringService.collect_metrics"
echo "3. Test N+1 detection: Start Rails server and check for Bullet alerts"
echo "4. Run load tests: ./scripts/load_test.sh"
echo
echo "🔧 Configuration Files Created:"
echo "  - config/initializers/bullet.rb"
echo "  - config/initializers/redis.rb"
echo "  - config/initializers/sidekiq.rb"
echo "  - app/services/optimized_dashboard_service.rb"
echo "  - app/services/performance_monitoring_service.rb"
echo "  - scripts/performance_benchmark.rb"
echo "  - scripts/load_test.sh"
echo
echo "💡 For production deployment:"
echo "  - Set REDIS_URL environment variable"
echo "  - Start Sidekiq worker: bundle exec sidekiq"
echo "  - Monitor cache hit rates and database performance"
echo
echo "🎯 Performance Targets:"
echo "  - Dashboard: <150ms"
echo "  - Critical path: <200ms"
echo "  - Database queries: <10 per request"
echo "  - Cache hit rate: >70%"
echo
echo "Run 'ruby scripts/performance_benchmark.rb' to test current performance!"