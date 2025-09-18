class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Composite indexes for activity feeds - critical for performance
    add_index :activity_feeds, [:actor_id, :is_public, :occurred_at],
              name: 'index_activity_feeds_actor_public_time',
              comment: 'Optimizes friend activity queries with privacy filtering'

    add_index :activity_feeds, [:user_id, :is_public, :occurred_at],
              name: 'index_activity_feeds_user_public_time',
              comment: 'Optimizes user feed queries with privacy filtering'

    add_index :activity_feeds, [:is_public, :action_type, :occurred_at],
              name: 'index_activity_feeds_public_type_time',
              comment: 'Optimizes trending and public feed queries by type'

    # Note: Skipping GIN index for metadata as it uses json type (not jsonb)
    # GIN indexes require jsonb columns for optimal performance

    # Friend relationship optimization indexes
    add_index :connections, [:user_id, :status, :updated_at],
              name: 'index_connections_user_status_time',
              comment: 'Optimizes friend list queries with status filtering'

    add_index :connections, [:partner_id, :status, :updated_at],
              name: 'index_connections_partner_status_time',
              comment: 'Optimizes reverse friend lookups'

    # User interactions optimization
    add_index :user_interactions, [:target_type, :target_id, :interaction_type, :created_at],
              name: 'index_user_interactions_target_type_time',
              comment: 'Optimizes interaction counts and recent interactions'

    # Activity comments threading optimization
    add_index :activity_comments, [:parent_id, :created_at],
              name: 'index_activity_comments_parent_time',
              comment: 'Optimizes threaded comment queries'

    # Analytics events for dashboard metrics
    add_index :analytics_events, [:user_id, :event_type, :created_at],
              name: 'index_analytics_events_user_type_time',
              comment: 'Optimizes user analytics and dashboard metrics'
  end
end
