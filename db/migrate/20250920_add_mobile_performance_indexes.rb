class AddMobilePerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Mobile-optimized composite indexes
    add_index :wishlists, [:user_id, :visibility, :updated_at],
              name: 'idx_wishlists_mobile_feed'
    add_index :wishlists, [:visibility, :event_type, :event_date],
              name: 'idx_wishlists_discovery'
    add_index :wishlist_items, [:wishlist_id, :status, :created_at],
              name: 'idx_items_mobile_list'
    add_index :wishlist_items, [:price, :currency, :created_at],
              name: 'idx_items_trending'

    # Mobile-specific caching indexes
    add_index :url_metadata_cache, [:url, :expires_at],
              name: 'idx_url_cache_mobile'
    add_index :analytics_events, [:user_id, :event_name, :created_at],
              name: 'idx_analytics_mobile'

    # Connection performance for friend feeds
    add_index :connections, [:user_id, :status, :partner_id],
              name: 'idx_connections_mobile'
    add_index :connections, [:partner_id, :status, :user_id],
              name: 'idx_connections_reverse_mobile'
  end
end