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

      # Broadcast to real-time channels if activity was created successfully
      if activity_feed
        broadcast_activity(activity_feed)
      end

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

    def broadcast_activity(activity_feed)
      # Rate limiting for broadcasts - max 20 per minute per user
      return unless check_broadcast_rate_limit(activity_feed.actor)

      # Broadcast to the activity owner's personal feed
      ActionCable.server.broadcast(
        "activity_feed_#{activity_feed.user.id}",
        {
          type: 'new_activity',
          activity: serialize_activity_for_broadcast(activity_feed)
        }
      )

      # Broadcast to public feed if activity is public
      if activity_feed.is_public?
        ActionCable.server.broadcast(
          "activity_feed_public",
          {
            type: 'new_activity',
            activity: serialize_activity_for_broadcast(activity_feed)
          }
        )
      end

      # Broadcast to friends' feeds based on action type and relationships
      broadcast_to_friends(activity_feed) if should_broadcast_to_friends?(activity_feed)
    rescue => e
      Rails.logger.error "Failed to broadcast activity: #{e.message}"
      # Don't fail the entire operation for broadcast errors
    end

    def serialize_activity_for_broadcast(activity)
      {
        id: activity.id,
        action_type: activity.action_type,
        action_description: activity.action_description,
        actor: {
          id: activity.actor.id,
          name: activity.actor.name,
          avatar_url: activity.actor.profile_avatar_url
        },
        target: serialize_target_for_broadcast(activity.target),
        user: {
          id: activity.user.id,
          name: activity.user.name
        },
        metadata: activity.metadata,
        occurred_at: activity.occurred_at,
        time_ago: ActionController::Base.helpers.time_ago_in_words(activity.occurred_at),
        is_public: activity.is_public?
      }
    end

    def serialize_target_for_broadcast(target)
      return nil unless target

      case target
      when Wishlist
        {
          id: target.id,
          name: target.name,
          type: 'Wishlist',
          url: Rails.application.routes.url_helpers.wishlist_path(target),
          cover_image_url: target.cover_image_url,
          visibility: target.visibility,
          event_type: target.event_type
        }
      when WishlistItem
        {
          id: target.id,
          name: target.name,
          type: 'WishlistItem',
          url: Rails.application.routes.url_helpers.wishlist_wishlist_item_path(target.wishlist, target),
          image_url: target.image_url,
          price: target.price,
          currency: target.currency,
          wishlist_name: target.wishlist.name
        }
      when User
        {
          id: target.id,
          name: target.name,
          type: 'User',
          avatar_url: target.profile_avatar_url
        }
      else
        {
          id: target.id,
          type: target.class.name
        }
      end
    end

    def broadcast_to_friends(activity_feed)
      # Get all friends of the activity actor
      actor = activity_feed.actor
      friend_ids = actor.connections.accepted.pluck(:partner_id) +
                   actor.inverse_connections.accepted.pluck(:user_id)

      # Broadcast to each friend's personal feed
      friend_ids.each do |friend_id|
        ActionCable.server.broadcast(
          "activity_feed_friends_#{friend_id}",
          {
            type: 'friend_activity',
            activity: serialize_activity_for_broadcast(activity_feed)
          }
        )
      end
    end

    def should_broadcast_to_friends?(activity_feed)
      # Only broadcast certain types of activities to friends
      friend_worthy_actions = %w[
        wishlist_created item_added item_purchased
        friend_connected wishlist_shared
      ]

      friend_worthy_actions.include?(activity_feed.action_type) && activity_feed.is_public?
    end

    def check_broadcast_rate_limit(user)
      # Rate limiting for broadcasts - max 20 per minute per user
      cache_key = "activity_broadcast_#{user.id}"
      current_count = Rails.cache.read(cache_key) || 0

      if current_count >= 20
        Rails.logger.warn "Broadcast rate limit exceeded for user #{user.id}"
        return false
      end

      Rails.cache.write(cache_key, current_count + 1, expires_in: 1.minute)
      true
    end
  end
end