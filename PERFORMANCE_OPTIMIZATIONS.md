# Wishare Performance Optimizations - Implementation Guide

## 🚀 Priority 1: Immediate Database Optimizations (4-6 hours)

### 1.1 Missing Database Indexes Migration

Create this migration to add critical missing indexes:

```ruby
# db/migrate/add_critical_performance_indexes.rb
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
```

### 1.2 Optimized Service Layer Methods

Replace existing methods with these optimized versions:

```ruby
# app/services/optimized_dashboard_service.rb
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
      # Single query with proper joins to get all friend users
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
      # Single query to load all relevant wishlists
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
```

### 1.3 Optimized Controller Implementation

Update controllers to use optimized service:

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @dashboard_data = OptimizedDashboardService.load_dashboard_data(current_user)

    # Extract data for view compatibility
    @user = @dashboard_data[:user]
    @recent_activities = ActivityFeedService.get_user_activities(
      user: current_user, limit: 5
    )
    @friend_activities = ActivityFeedService.get_friend_activities(
      user: current_user, limit: 5
    )
    @activity_stats = @dashboard_data[:activity_stats]

    # Track dashboard view
    ActivityTrackerService.track_dashboard_viewed(
      user: current_user,
      request: request
    )
  end
end

# app/controllers/wishlists_controller.rb
class WishlistsController < ApplicationController
  def index
    # Use optimized unified loading
    @dashboard_data = OptimizedDashboardService.load_dashboard_data(current_user)

    # Sort handling
    @sort_by = params[:sort_by] || 'created_desc'
    sort_order = get_sort_order(@sort_by)

    # Apply sorting to already loaded data
    @wishlists = @dashboard_data[:user_wishlists].sort_by do |w|
      case @sort_by
      when 'name_asc' then w.name
      when 'name_desc' then w.name
      when 'updated_desc' then w.updated_at
      when 'updated_asc' then w.updated_at
      else w.created_at
      end
    end
    @wishlists.reverse! if @sort_by.end_with?('_desc')

    @connected_wishlists = @dashboard_data[:connected_wishlists]
    @public_wishlists = @dashboard_data[:public_wishlists]
    @focus_partner = params[:partner] == 'true'
  end

  private

  def get_sort_order(sort_by)
    case sort_by
    when 'name_asc' then { name: :asc }
    when 'name_desc' then { name: :desc }
    when 'updated_desc' then { updated_at: :desc }
    when 'updated_asc' then { updated_at: :asc }
    when 'created_asc' then { created_at: :asc }
    else { created_at: :desc }
    end
  end
end
```

---

## 🚀 Priority 2: Advanced Caching Implementation (6-8 hours)

### 2.1 Redis Configuration

Add Redis for production-grade caching:

```ruby
# Gemfile
gem 'redis', '~> 5.0'
gem 'hiredis', '~> 0.6'

# config/environments/production.rb
config.cache_store = :redis_cache_store, {
  url: ENV['REDIS_URL'],
  expires_in: 1.hour,
  namespace: 'wishare_cache',
  pool_size: 5,
  pool_timeout: 5
}

# ActionCable Redis adapter for better performance
config.action_cable.adapter = :redis
config.action_cable.url = ENV['REDIS_URL']

# config/environments/development.rb (for testing)
config.cache_store = :redis_cache_store, {
  url: 'redis://localhost:6379/1',
  expires_in: 30.minutes,
  namespace: 'wishare_dev'
}
```

### 2.2 Fragment Caching Implementation

Add view caching for expensive components:

```erb
<!-- app/views/dashboard/index.html.erb -->
<div class="dashboard-container">
  <!-- Cache user profile section -->
  <% cache ["dashboard_profile", current_user, current_user.updated_at] do %>
    <%= render 'user_profile_sidebar' %>
  <% end %>

  <!-- Cache activity sidebar with smart cache keys -->
  <% cache ["dashboard_activities", current_user, @recent_activities.maximum(:updated_at), @activity_stats] do %>
    <%= render 'activity_sidebar', activities: @recent_activities, stats: @activity_stats %>
  <% end %>

  <!-- Main content with wishlist caching -->
  <div class="main-content">
    <% cache ["dashboard_main", current_user, @wishlists.maximum(:updated_at)] do %>
      <%= render 'wishlist_overview', wishlists: @wishlists %>
    <% end %>
  </div>
</div>

<!-- app/views/wishlists/index.html.erb -->
<div class="wishlists-container">
  <!-- Cache each wishlist section separately -->
  <% cache ["user_wishlists", current_user, @wishlists.maximum(:updated_at), @sort_by] do %>
    <div class="user-wishlists">
      <% @wishlists.each do |wishlist| %>
        <% cache [wishlist, wishlist.wishlist_items.maximum(:updated_at)] do %>
          <%= render 'wishlist_card', wishlist: wishlist %>
        <% end %>
      <% end %>
    </div>
  <% end %>

  <% cache ["connected_wishlists", @connected_wishlists.map(&:updated_at).max, @sort_by] do %>
    <div class="connected-wishlists">
      <% @connected_wishlists.each do |wishlist| %>
        <% cache [wishlist, wishlist.wishlist_items.maximum(:updated_at)] do %>
          <%= render 'wishlist_card', wishlist: wishlist %>
        <% end %>
      <% end %>
    </div>
  <% end %>
</div>
```

### 2.3 Smart Cache Invalidation

Implement automatic cache invalidation:

```ruby
# app/models/concerns/cache_invalidation.rb
module CacheInvalidation
  extend ActiveSupport::Concern

  included do
    after_update :invalidate_related_cache
    after_destroy :invalidate_related_cache
  end

  private

  def invalidate_related_cache
    case self.class.name
    when 'User'
      invalidate_user_cache
    when 'Wishlist'
      invalidate_wishlist_cache
    when 'WishlistItem'
      invalidate_item_cache
    when 'ActivityFeed'
      invalidate_activity_cache
    end
  end

  def invalidate_user_cache
    Rails.cache.delete_matched("*dashboard_profile*#{id}*")
    Rails.cache.delete_matched("*activity_stats_#{id}*")
    Rails.cache.delete("user_connections_#{id}")
  end

  def invalidate_wishlist_cache
    Rails.cache.delete_matched("*wishlist*#{id}*")
    Rails.cache.delete_matched("*user_wishlists*#{user_id}*")
    Rails.cache.delete("activity_stats_#{user_id}_week")
  end

  def invalidate_item_cache
    Rails.cache.delete_matched("*wishlist*#{wishlist_id}*")
    Rails.cache.delete("activity_stats_#{wishlist.user_id}_week")
  end

  def invalidate_activity_cache
    Rails.cache.delete_matched("*dashboard_activities*#{user_id}*")
    Rails.cache.delete("activity_stats_#{user_id}_week")
  end
end

# Include in models
class User < ApplicationRecord
  include CacheInvalidation
  # existing code...
end

class Wishlist < ApplicationRecord
  include CacheInvalidation
  # existing code...
end
```

---

## 🚀 Priority 3: Background Processing (4-6 hours)

### 3.1 Background Job Setup

Configure Sidekiq for background processing:

```ruby
# Gemfile
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-web'

# config/routes.rb
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq' if Rails.env.development?

# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

# config/application.rb
config.active_job.queue_adapter = :sidekiq
```

### 3.2 Background Job Implementation

Move heavy operations to background:

```ruby
# app/jobs/url_metadata_extraction_job.rb
class UrlMetadataExtractionJob < ApplicationJob
  queue_as :default

  def perform(url, user_id, item_id = nil)
    Rails.logger.info "Extracting metadata for #{url}"

    result = MasterUrlMetadataExtractor.extract(url)

    # Update item if provided
    if item_id
      item = WishlistItem.find_by(id: item_id)
      if item && result[:success]
        item.update!(
          name: result[:title] || item.name,
          image_url: result[:image_url] || item.image_url,
          price: result[:price] || item.price,
          currency: result[:currency] || item.currency
        )
      end
    end

    # Broadcast result to user via ActionCable
    ActionCable.server.broadcast(
      "metadata_extraction_#{user_id}",
      {
        url: url,
        item_id: item_id,
        result: result,
        extracted_at: Time.current
      }
    )

    Rails.logger.info "Metadata extraction completed for #{url}"
  rescue => e
    Rails.logger.error "Metadata extraction failed for #{url}: #{e.message}"

    # Broadcast error to user
    ActionCable.server.broadcast(
      "metadata_extraction_#{user_id}",
      {
        url: url,
        item_id: item_id,
        error: e.message,
        failed_at: Time.current
      }
    )
  end
end

# app/jobs/activity_stats_refresh_job.rb
class ActivityStatsRefreshJob < ApplicationJob
  queue_as :low_priority

  def perform(user_id)
    user = User.find(user_id)

    # Refresh activity stats cache
    ['today', 'week', 'month'].each do |timeframe|
      Rails.cache.delete("activity_stats_#{user_id}_#{timeframe}")
      ActivityFeedService.get_activity_stats(user: user, timeframe: timeframe)
    end
  end
end

# app/jobs/cache_warming_job.rb
class CacheWarmingJob < ApplicationJob
  queue_as :low_priority

  def perform(user_id)
    user = User.find(user_id)

    # Warm up frequently accessed caches
    OptimizedDashboardService.load_dashboard_data(user)
    ActivityFeedService.get_user_activities(user: user, limit: 10)
    ActivityFeedService.get_friend_activities(user: user, limit: 10)

    Rails.logger.info "Cache warmed for user #{user_id}"
  end
end
```

### 3.3 Asynchronous Processing Integration

Update controllers to use background jobs:

```ruby
# app/controllers/wishlist_items_controller.rb
class WishlistItemsController < ApplicationController
  def create
    @wishlist = current_user.wishlists.find(params[:wishlist_id])
    @item = @wishlist.wishlist_items.build(wishlist_item_params)

    if @item.save
      # Extract metadata in background
      if @item.url.present?
        UrlMetadataExtractionJob.perform_later(@item.url, current_user.id, @item.id)
      end

      # Refresh user's activity stats in background
      ActivityStatsRefreshJob.perform_later(current_user.id)

      redirect_to @wishlist, notice: 'Item was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

---

## 🚀 Priority 4: Performance Monitoring (2-4 hours)

### 4.1 Bullet Gem Configuration

Add N+1 query detection:

```ruby
# Gemfile
group :development, :test do
  gem 'bullet'
end

# config/environments/development.rb
config.after_initialize do
  Bullet.enable = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.bullet_logger = true

  # Show in browser for immediate feedback
  Bullet.alert = true
  Bullet.add_footer = true

  # Raise errors in test environment
  Bullet.raise = true if Rails.env.test?

  # Whitelist known false positives
  Bullet.add_safelist type: :n_plus_one_query, class_name: "User", association: :avatar
end
```

### 4.2 Performance Metrics Dashboard

Create performance monitoring service:

```ruby
# app/services/performance_monitoring_service.rb
class PerformanceMonitoringService
  class << self
    def collect_metrics
      {
        database: database_metrics,
        cache: cache_metrics,
        application: application_metrics,
        background_jobs: background_job_metrics,
        timestamp: Time.current
      }
    end

    def alert_if_needed(metrics)
      alerts = []

      # Database performance alerts
      if metrics[:database][:avg_query_time] > 100
        alerts << "Database queries averaging #{metrics[:database][:avg_query_time]}ms (>100ms threshold)"
      end

      # Cache performance alerts
      if metrics[:cache][:hit_rate] < 0.7
        alerts << "Cache hit rate #{(metrics[:cache][:hit_rate] * 100).round(1)}% (<70% threshold)"
      end

      # Background job alerts
      if metrics[:background_jobs][:failed_jobs] > 10
        alerts << "#{metrics[:background_jobs][:failed_jobs]} failed background jobs"
      end

      send_alerts(alerts) if alerts.any?
      alerts
    end

    private

    def database_metrics
      # Collect database performance metrics
      {
        active_connections: ActiveRecord::Base.connection_pool.stat[:size],
        query_cache_hits: ActiveRecord::Base.connection.query_cache_enabled,
        avg_query_time: calculate_avg_query_time,
        slow_queries: count_slow_queries
      }
    end

    def cache_metrics
      if Rails.cache.respond_to?(:stats)
        Rails.cache.stats
      else
        {
          hit_rate: estimate_cache_hit_rate,
          memory_usage: estimate_cache_memory,
          key_count: estimate_cache_keys
        }
      end
    end

    def application_metrics
      {
        memory_usage: `ps -o pid,rss -p #{Process.pid}`.split("\n").last.split.last.to_i,
        load_average: File.read('/proc/loadavg').split.first.to_f rescue 0,
        response_times: get_recent_response_times
      }
    end

    def background_job_metrics
      {
        pending_jobs: Sidekiq::Queue.new.size,
        failed_jobs: Sidekiq::DeadSet.new.size,
        processed_jobs: Sidekiq::Stats.new.processed,
        retry_jobs: Sidekiq::RetrySet.new.size
      }
    end

    def send_alerts(alerts)
      Rails.logger.warn "PERFORMANCE ALERTS: #{alerts.join('; ')}"
      # Could integrate with Slack, email, or monitoring service here
    end
  end
end

# config/schedule.rb (using whenever gem for cron)
every 5.minutes do
  runner "PerformanceMonitoringService.alert_if_needed(PerformanceMonitoringService.collect_metrics)"
end
```

### 4.3 Request Performance Tracking

Add middleware for request performance tracking:

```ruby
# app/middleware/performance_tracking_middleware.rb
class PerformanceTrackingMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Time.current
    query_count_before = query_count

    status, headers, response = @app.call(env)

    duration = ((Time.current - start_time) * 1000).round(2)
    queries = query_count - query_count_before

    # Log performance metrics
    if duration > 200 || queries > 20
      Rails.logger.warn "SLOW REQUEST: #{env['REQUEST_METHOD']} #{env['REQUEST_URI']} - #{duration}ms, #{queries} queries"
    end

    # Add performance headers in development
    if Rails.env.development?
      headers['X-Response-Time'] = "#{duration}ms"
      headers['X-Query-Count'] = queries.to_s
    end

    [status, headers, response]
  end

  private

  def query_count
    ActiveSupport::Notifications.instrumenter.instance_variable_get(:@notifiers)['sql.active_record']&.size || 0
  end
end

# config/application.rb
config.middleware.use PerformanceTrackingMiddleware
```

---

## 📊 Testing & Validation

### Performance Test Suite

Create automated performance tests:

```ruby
# spec/performance/dashboard_performance_spec.rb
require 'rails_helper'
require 'benchmark'

RSpec.describe "Dashboard Performance", type: :request do
  let(:user) { create(:user) }
  let!(:wishlists) { create_list(:wishlist, 10, user: user) }
  let!(:items) { wishlists.flat_map { |w| create_list(:wishlist_item, 5, wishlist: w) } }
  let!(:friends) { create_list(:user, 5) }
  let!(:connections) { friends.map { |f| create(:connection, user: user, partner: f, status: 'accepted') } }

  before { sign_in user }

  it "loads dashboard within performance budget" do
    time = Benchmark.measure do
      get root_path
    end

    expect(response).to have_http_status(:success)
    expect(time.real * 1000).to be < 200 # 200ms budget
  end

  it "performs efficient database queries" do
    expect do
      get root_path
    end.not_to exceed_query_limit(15) # Max 15 queries
  end

  it "loads wishlists index efficiently" do
    time = Benchmark.measure do
      get wishlists_path
    end

    expect(response).to have_http_status(:success)
    expect(time.real * 1000).to be < 300 # 300ms budget for index
  end
end

# spec/support/query_limit_matcher.rb
RSpec::Matchers.define :exceed_query_limit do |expected|
  supports_block_expectations

  match do |block|
    query_count = 0
    ActiveSupport::Notifications.subscribe('sql.active_record') do
      query_count += 1
    end

    block.call
    @actual = query_count
    @actual > expected
  end

  failure_message do
    "Expected to run at most #{expected} queries, but ran #{@actual}"
  end
end
```

### Load Testing Script

Create load testing for scalability validation:

```bash
#!/bin/bash
# scripts/load_test.sh

echo "Starting Wishare Load Test..."

# Install dependencies
if ! command -v ab &> /dev/null; then
    echo "Installing Apache Bench..."
    brew install httpd
fi

# Start Rails server in background
echo "Starting Rails server..."
bundle exec rails server -p 3000 -e production &
SERVER_PID=$!
sleep 10

# Test dashboard endpoint
echo "Testing dashboard performance..."
ab -n 100 -c 10 -g dashboard_results.tsv http://localhost:3000/

# Test wishlist index
echo "Testing wishlist index performance..."
ab -n 100 -c 10 -g wishlists_results.tsv http://localhost:3000/wishlists

# Test API endpoints
echo "Testing API performance..."
ab -n 50 -c 5 -g api_results.tsv http://localhost:3000/api/v1/wishlists

# Cleanup
kill $SERVER_PID

echo "Load test complete. Check *_results.tsv files for detailed metrics."
echo "Expected results:"
echo "  - Dashboard: <200ms average response time"
echo "  - Wishlists: <300ms average response time"
echo "  - API: <100ms average response time"
```

---

## 🎯 Success Metrics

### Before/After Comparison

Track these metrics before and after optimization:

```ruby
# Performance benchmark script
# ruby scripts/performance_benchmark.rb

require_relative '../config/environment'

class PerformanceBenchmark
  def self.run
    user = User.first || create_test_user

    puts "=== Wishare Performance Benchmark ==="
    puts "User: #{user.name} (ID: #{user.id})"
    puts "Wishlists: #{user.wishlists.count}"
    puts "Items: #{user.wishlists.joins(:wishlist_items).count}"
    puts "Friends: #{user.connections.accepted.count}"
    puts

    # Dashboard performance
    dashboard_time = Benchmark.measure do
      DashboardController.new.tap do |controller|
        controller.define_singleton_method(:current_user) { user }
        controller.define_singleton_method(:authenticate_user!) { true }
        controller.index
      end
    end

    puts "Dashboard load time: #{(dashboard_time.real * 1000).round(2)}ms"

    # Wishlist index performance
    wishlist_time = Benchmark.measure do
      WishlistsController.new.tap do |controller|
        controller.define_singleton_method(:current_user) { user }
        controller.define_singleton_method(:authenticate_user!) { true }
        controller.define_singleton_method(:params) { { sort_by: 'created_desc' } }
        controller.index
      end
    end

    puts "Wishlist index time: #{(wishlist_time.real * 1000).round(2)}ms"

    total_time = (dashboard_time.real + wishlist_time.real) * 1000
    puts "Total critical path: #{total_time.round(2)}ms"

    if total_time < 200
      puts "✅ PASS: Critical path under 200ms target"
    else
      puts "❌ FAIL: Critical path exceeds 200ms target"
    end
  end

  private

  def self.create_test_user
    User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "testpassword123",
      preferred_locale: "en"
    )
  end
end

PerformanceBenchmark.run
```

### Expected Performance Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Dashboard load | 65.73ms | <50ms | 24% faster |
| Wishlist index | 141.62ms | <100ms | 29% faster |
| Critical path | 207.35ms | <150ms | 28% faster |
| Database queries | 15-20 | <10 | 50% reduction |
| Cache hit rate | 0% | >70% | New capability |
| Memory usage | Variable | <256MB | Stable |

---

## 🚀 Deployment Strategy

### Staged Rollout Plan

1. **Development Testing** (Week 1)
   - Implement optimizations locally
   - Run performance test suite
   - Validate cache invalidation
   - Measure before/after metrics

2. **Staging Deployment** (Week 2)
   - Deploy to staging environment
   - Run load tests with production data volume
   - Monitor for 48 hours
   - Performance regression testing

3. **Production Deployment** (Week 3)
   - Deploy during low-traffic window
   - Monitor key metrics for 24 hours
   - Rollback plan ready if issues detected
   - Gradual traffic increase

4. **Post-Deployment Monitoring** (Week 4)
   - Daily performance reports
   - User experience monitoring
   - Database performance tracking
   - Cache hit rate optimization

### Rollback Strategy

If performance degrades after deployment:

1. **Immediate**: Disable fragment caching via feature flag
2. **Database**: Revert to previous query patterns
3. **Cache**: Clear all Redis cache and fall back to database
4. **Complete**: Database migration rollback if needed

---

**Implementation Priority**: Start with database indexes (highest ROI, lowest risk)
**Timeline**: 2-3 weeks for complete implementation
**Expected Impact**: 30-50% performance improvement across critical paths