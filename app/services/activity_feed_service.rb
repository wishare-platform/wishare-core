class ActivityFeedService
  class << self
    # Generate activity feed for a user with filtering options
    def generate_feed(user:, feed_type: 'for_you', limit: 20, offset: 0)
      case feed_type
      when 'for_you'
        generate_personalized_feed(user, limit, offset)
      when 'friends'
        generate_friends_feed(user, limit, offset)
      when 'following'
        generate_following_feed(user, limit, offset)
      when 'all'
        generate_public_feed(user, limit, offset)
      else
        generate_personalized_feed(user, limit, offset)
      end
    end

    # Get activity counts for dashboard stats
    def get_activity_stats(user:, timeframe: 'week')
      case timeframe
      when 'today'
        get_daily_stats(user)
      when 'week'
        get_weekly_stats(user)
      when 'month'
        get_monthly_stats(user)
      else
        get_weekly_stats(user)
      end
    end

    # Get trending activities across the platform
    def get_trending_activities(limit: 10, timeframe: 'week')
      start_date = case timeframe
                   when 'today' then Date.current.beginning_of_day
                   when 'week' then 1.week.ago
                   when 'month' then 1.month.ago
                   else 1.week.ago
                   end

      ActivityFeed.joins(:target)
                  .where(occurred_at: start_date..Time.current)
                  .where(is_public: true)
                  .group(:action_type, :target_type)
                  .order('COUNT(*) DESC')
                  .limit(limit)
                  .count
    end

    # Get activities for a specific target (wishlist, item, etc.)
    def get_target_activities(target:, viewer: nil, limit: 10)
      activities = ActivityFeed.where(target: target)
                              .includes(:actor, :user, :target)
                              .recent
                              .limit(limit)

      # Filter based on privacy settings and viewer permissions
      activities = filter_by_privacy(activities, viewer) if viewer

      activities
    end

    # Get friend activities (for friends sidebar)
    def get_friend_activities(user:, limit: 5)
      friend_ids = get_friend_ids(user)
      return ActivityFeed.none if friend_ids.empty?

      ActivityFeed.where(actor_id: friend_ids)
                  .where(is_public: true)
                  .includes(:actor, :target, :user)
                  .recent
                  .limit(limit)
    end

    # Get user's own recent activities
    def get_user_activities(user:, limit: 10)
      ActivityFeed.where(actor: user)
                  .includes(:actor, :target, :user)
                  .recent
                  .limit(limit)
    end

    private

    # Generate personalized "For You" feed
    def generate_personalized_feed(user, limit, offset)
      # Get friend IDs
      friend_ids = get_friend_ids(user)

      # Personalized feed includes:
      # 1. Friend activities (weighted higher)
      # 2. Popular public activities
      # 3. Activities on user's content
      # 4. Trending activities in user's interests

      friend_activities = get_friend_activities_query(friend_ids, limit / 2)
      user_content_activities = get_user_content_activities_query(user, limit / 4)
      trending_activities = get_trending_activities_query(limit / 4)

      # Combine and order by relevance score
      combined_ids = (friend_activities.pluck(:id) +
                     user_content_activities.pluck(:id) +
                     trending_activities.pluck(:id)).uniq

      ActivityFeed.where(id: combined_ids)
                  .includes(:actor, :user, target: [:user])
                  .order(occurred_at: :desc)
                  .offset(offset)
                  .limit(limit)
    end

    # Generate friends-only feed
    def generate_friends_feed(user, limit, offset)
      friend_ids = get_friend_ids(user)
      return ActivityFeed.none if friend_ids.empty?

      ActivityFeed.where(actor_id: friend_ids)
                  .where(is_public: true)
                  .includes(:actor, :user, target: [:user])
                  .recent
                  .offset(offset)
                  .limit(limit)
    end

    # Generate following feed (users they follow - can be extended later)
    def generate_following_feed(user, limit, offset)
      # For now, same as friends feed
      # Later can be extended with actual following relationship
      generate_friends_feed(user, limit, offset)
    end

    # Generate public feed (all public activities)
    def generate_public_feed(user, limit, offset)
      ActivityFeed.public_activities
                  .includes(:actor, :user, target: [:user])
                  .recent
                  .offset(offset)
                  .limit(limit)
    end

    # Helper methods

    def get_friend_ids(user)
      user.connections.accepted.pluck(:partner_id) +
      user.inverse_connections.accepted.pluck(:user_id)
    end

    def get_friend_activities_query(friend_ids, limit)
      return ActivityFeed.none if friend_ids.empty?

      ActivityFeed.where(actor_id: friend_ids)
                  .where(is_public: true)
                  .recent
                  .limit(limit)
    end

    def get_user_content_activities_query(user, limit)
      # Activities on user's wishlists and items
      ActivityFeed.where(user: user)
                  .where.not(actor: user) # Exclude user's own activities
                  .where(is_public: true)
                  .recent
                  .limit(limit)
    end

    def get_trending_activities_query(limit)
      # Get activities from last 7 days that have high engagement
      ActivityFeed.where(occurred_at: 1.week.ago..Time.current)
                  .where(is_public: true)
                  .joins("LEFT JOIN user_interactions ON user_interactions.target_type = 'ActivityFeed' AND user_interactions.target_id = activity_feeds.id")
                  .group('activity_feeds.id')
                  .order('COUNT(user_interactions.id) DESC')
                  .limit(limit)
    end

    def filter_by_privacy(activities, viewer)
      # Filter activities based on privacy settings and viewer's relationship to actors
      activities.select do |activity|
        can_view_activity?(activity, viewer)
      end
    end

    def can_view_activity?(activity, viewer)
      # Public activities are always visible
      return true if activity.is_public?

      # User can always see their own activities
      return true if activity.actor == viewer || activity.user == viewer

      # Check if viewer is friends with the actor
      viewer.connected_to?(activity.actor)
    end

    # Stats methods

    def get_daily_stats(user)
      today = Date.current.beginning_of_day..Date.current.end_of_day
      get_stats_for_period(user, today)
    end

    def get_weekly_stats(user)
      week = 1.week.ago..Time.current
      get_stats_for_period(user, week)
    end

    def get_monthly_stats(user)
      month = 1.month.ago..Time.current
      get_stats_for_period(user, month)
    end

    def get_stats_for_period(user, period)
      activities = ActivityFeed.where(actor: user, occurred_at: period)

      {
        total_activities: activities.count,
        wishlists_created: activities.where(action_type: 'wishlist_created').count,
        items_added: activities.where(action_type: 'item_added').count,
        items_purchased: activities.where(action_type: 'item_purchased').count,
        likes_given: UserInteraction.where(user: user, interaction_type: 'like', created_at: period).count,
        comments_made: ActivityComment.where(user: user, created_at: period).count,
        friends_connected: activities.where(action_type: 'friend_connected').count
      }
    end
  end
end