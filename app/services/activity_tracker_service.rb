class ActivityTrackerService
  class << self
    # Main method to track activities - creates both ActivityFeed and AnalyticsEvent
    def track_activity(action_type:, actor:, target: nil, user: nil, request: nil, metadata: {}, is_public: true)
      # Ensure we have a user (either provided or use actor)
      feed_user = user || actor

      # Create activity feed entry for social features
      activity_feed = create_activity_feed(
        action_type: action_type,
        actor: actor,
        target: target,
        user: feed_user,
        metadata: metadata,
        is_public: is_public
      )

      # Create analytics event for tracking/metrics
      analytics_event = create_analytics_event(
        action_type: action_type,
        user: actor,
        request: request,
        metadata: metadata.merge(
          target_type: target&.class&.name,
          target_id: target&.id
        )
      )

      {
        activity_feed: activity_feed,
        analytics_event: analytics_event
      }
    end

    # Specific tracking methods for common actions
    def track_wishlist_created(user:, wishlist:, request: nil)
      track_activity(
        action_type: 'wishlist_created',
        actor: user,
        target: wishlist,
        request: request,
        metadata: {
          wishlist_name: wishlist.name,
          event_type: wishlist.event_type,
          visibility: wishlist.visibility
        }
      )
    end

    def track_item_added(user:, item:, request: nil)
      track_activity(
        action_type: 'item_added',
        actor: user,
        target: item,
        request: request,
        metadata: {
          item_name: item.name,
          wishlist_name: item.wishlist.name,
          price: item.price,
          currency: item.currency
        }
      )
    end

    def track_item_purchased(purchaser:, item:, request: nil)
      track_activity(
        action_type: 'item_purchased',
        actor: purchaser,
        target: item,
        user: item.wishlist.user, # Activity appears in wishlist owner's feed
        request: request,
        metadata: {
          item_name: item.name,
          wishlist_owner: item.wishlist.user.name,
          price: item.price,
          currency: item.currency
        }
      )
    end

    def track_wishlist_liked(user:, wishlist:, request: nil)
      track_activity(
        action_type: 'wishlist_liked',
        actor: user,
        target: wishlist,
        user: wishlist.user, # Activity appears in wishlist owner's feed
        request: request,
        metadata: {
          wishlist_name: wishlist.name,
          liker_name: user.name
        }
      )
    end

    def track_wishlist_commented(user:, wishlist:, comment:, request: nil)
      track_activity(
        action_type: 'wishlist_commented',
        actor: user,
        target: wishlist,
        user: wishlist.user, # Activity appears in wishlist owner's feed
        request: request,
        metadata: {
          wishlist_name: wishlist.name,
          commenter_name: user.name,
          comment_preview: comment.content.truncate(100)
        }
      )
    end

    def track_friend_connected(user:, friend:, request: nil)
      # Create activity for both users
      [
        track_activity(
          action_type: 'friend_connected',
          actor: user,
          target: friend,
          user: user,
          request: request,
          metadata: { friend_name: friend.name }
        ),
        track_activity(
          action_type: 'friend_connected',
          actor: friend,
          target: user,
          user: friend,
          request: request,
          metadata: { friend_name: user.name }
        )
      ]
    end

    def track_profile_updated(user:, request: nil, changes: {})
      track_activity(
        action_type: 'profile_updated',
        actor: user,
        target: user,
        request: request,
        metadata: {
          changes_made: changes.keys,
          change_count: changes.size
        }
      )
    end

    def track_wishlist_shared(user:, wishlist:, platform:, request: nil)
      track_activity(
        action_type: 'wishlist_shared',
        actor: user,
        target: wishlist,
        request: request,
        metadata: {
          wishlist_name: wishlist.name,
          platform: platform
        }
      )
    end

    # Dashboard-specific tracking
    def track_dashboard_viewed(user:, request: nil)
      create_analytics_event(
        action_type: 'dashboard_viewed',
        user: user,
        request: request
      )
    end

    def track_activity_feed_viewed(user:, request: nil, feed_type: 'all')
      create_analytics_event(
        action_type: 'activity_feed_viewed',
        user: user,
        request: request,
        metadata: { feed_type: feed_type }
      )
    end

    def track_trending_item_clicked(user:, item:, request: nil)
      create_analytics_event(
        action_type: 'trending_item_clicked',
        user: user,
        request: request,
        metadata: {
          item_name: item.name,
          item_id: item.id,
          wishlist_id: item.wishlist_id
        }
      )
    end

    private

    def create_activity_feed(action_type:, actor:, target:, user:, metadata:, is_public:)
      return nil unless target # Some activities don't have targets

      ActivityFeed.create_activity(
        action_type: action_type,
        actor: actor,
        target: target,
        user: user,
        metadata: metadata,
        is_public: is_public
      )
    rescue => e
      Rails.logger.error "Failed to create activity feed: #{e.message}"
      nil
    end

    def create_analytics_event(action_type:, user:, request:, metadata: {})
      # Map activity action types to analytics event types
      analytics_event_type = map_to_analytics_event_type(action_type)
      return nil unless analytics_event_type

      AnalyticsEvent.track(
        analytics_event_type,
        user: user,
        request: request,
        session_id: request&.session&.id || 'system-generated',
        **metadata
      )
    rescue => e
      Rails.logger.error "Failed to create analytics event: #{e.message}"
      nil
    end

    def map_to_analytics_event_type(action_type)
      mapping = {
        'wishlist_created' => :wishlist_created,
        'item_added' => :item_added,
        'item_purchased' => :item_purchased,
        'wishlist_liked' => :wishlist_liked,
        'wishlist_commented' => :wishlist_commented,
        'item_commented' => :item_commented,
        'friend_connected' => :connection_formed,
        'profile_updated' => :page_view, # Could be more specific
        'wishlist_shared' => :wishlist_shared,
        'dashboard_viewed' => :dashboard_viewed,
        'activity_feed_viewed' => :activity_feed_viewed,
        'trending_item_clicked' => :trending_item_clicked
      }

      mapping[action_type]
    end
  end
end