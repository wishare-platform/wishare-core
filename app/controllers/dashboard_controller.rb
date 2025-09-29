class DashboardController < ApplicationController
  include ProductionErrorHandling

  before_action :authenticate_user!
  before_action :ensure_dashboard_data, only: [:api_data]

  def index
    @user = current_user

    begin
      # Track dashboard view for analytics
      ActivityTrackerService.track_dashboard_viewed(
        user: current_user,
        request: request
      )

      # Pre-load data for efficient sidebar rendering with error handling
      @recent_activities = ActivityFeedService.get_user_activities(
        user: current_user,
        limit: 5
      )

      @friend_activities = ActivityFeedService.get_friend_activities(
        user: current_user,
        limit: 5
      )

      # Get activity statistics for the past week
      @activity_stats = ActivityFeedService.get_activity_stats(
        user: current_user,
        timeframe: 'week'
      )

      # Pre-load friends data for sidebar with proper eager loading
      @connections = current_user.accepted_connections.includes(partner: :avatar_attachment)
      @inverse_connections = current_user.inverse_connections.accepted_connections.includes(user: :avatar_attachment)

      # Pre-load friend activity data and wishlist counts to prevent N+1 queries
      friend_ids = @connections.map(&:partner_id) + @inverse_connections.map(&:user_id)
      if friend_ids.any?
        # Pre-load recent activity for all friends in a single query
        @friend_recent_activities = ActivityFeed.where(actor_id: friend_ids)
                                              .where('occurred_at > ?', 1.week.ago)
                                              .where(is_public: true)
                                              .order(occurred_at: :desc)
                                              .group_by(&:actor_id)
                                              .transform_values(&:first) # Only keep the most recent per friend

        # Pre-load wishlist counts for all friends in a single query
        @friend_wishlist_counts = Wishlist.where(user_id: friend_ids)
                                         .where(visibility: [:partner_only, :publicly_visible])
                                         .group(:user_id)
                                         .count
      else
        @friend_recent_activities = {}
        @friend_wishlist_counts = {}
      end

      # Set success flag for frontend
      @dashboard_loaded = true

    rescue StandardError => e
      Rails.logger.error "Dashboard loading error for user #{current_user&.id || 'unknown'}: #{e.message}"
      Rails.logger.error "Dashboard loading backtrace: #{e.backtrace.first(10).join('\n')}"

      # Provide fallback data to prevent infinite loading
      @recent_activities = ActivityFeed.none
      @friend_activities = ActivityFeed.none
      @activity_stats = { total_activities: 0, this_week: 0 }
      @friend_recent_activities = {}
      @friend_wishlist_counts = {}
      @connections = current_user.accepted_connections.includes(partner: :avatar_attachment)
      @inverse_connections = current_user.inverse_connections.accepted_connections.includes(user: :avatar_attachment)
      @dashboard_loaded = false
      @dashboard_error = e.message

      # Don't raise the error, let the view handle the fallback gracefully
    end
  end

  # API endpoint for mobile/AJAX dashboard data
  def api_data
    # Always ensure we have current data for API calls
    Rails.logger.info "Dashboard API request - User: #{current_user&.id}, User Agent: #{request.user_agent}"

    begin
      # Get user activities with cursor support
      activities_result = ActivityFeedService.get_user_activities(
        user: current_user,
        limit: 15
      )
      @recent_activities = activities_result.is_a?(Hash) ? activities_result[:activities] : activities_result

      @friend_activities ||= ActivityFeedService.get_friend_activities(
        user: current_user,
        limit: 12
      )

      @activity_stats ||= ActivityFeedService.get_activity_stats(
        user: current_user,
        timeframe: 'week'
      )

      # Convert activities to simple JSON format for frontend
      recent_activities_json = @recent_activities.map do |activity|
        {
          id: activity.id,
          action_type: activity.action_type,
          action_description: activity_description(activity),
          time_ago: helpers.time_ago_in_words(activity.created_at),
          actor: {
            id: activity.actor.id,
            name: activity.actor.name,
            avatar_url: activity.actor.profile_avatar_url
          },
          target: activity.target ? {
            type: activity.target.class.name,
            id: activity.target.id,
            name: activity.target.respond_to?(:name) ? activity.target.name : activity.target.to_s,
            url: activity.target.respond_to?(:to_param) ?
                  (activity.target.is_a?(WishlistItem) ?
                    wishlist_wishlist_item_path(activity.target.wishlist, activity.target) :
                    url_for(activity.target)) : '#'
          } : nil
        }
      end

      render json: {
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          avatar_url: current_user.profile_avatar_url
        },
        recent_activities: recent_activities_json,
        friend_activities: [],  # Simplified for fallback
        activity_stats: @activity_stats || { total_activities: 0, this_week: 0 },
        loaded: true,
        http_fallback: true
      }
    rescue StandardError => e
      Rails.logger.error "Dashboard API error for user #{current_user&.id || 'unknown'}: #{e.message}"
      Rails.logger.error "Dashboard API error backtrace: #{e.backtrace.first(10).join('\n')}"

      # Enhanced error response with more debugging info
      error_details = {
        error: 'Failed to load dashboard data',
        loaded: false,
        fallback: true,
        message: 'Unable to load your activity feed. Please try refreshing the page.',
        debug_info: Rails.env.production? ? nil : {
          error_class: e.class.name,
          error_message: e.message,
          user_id: current_user&.id,
          timestamp: Time.current.iso8601
        }
      }

      render json: error_details, status: :internal_server_error
    end
  end

  private

  def activity_description(activity)
    case activity.action_type
    when 'wishlist_created'
      t('dashboard.activity_descriptions.wishlist_created')
    when 'item_added'
      t('dashboard.activity_descriptions.item_added')
    when 'item_purchased'
      t('dashboard.activity_descriptions.item_purchased')
    when 'wishlist_liked'
      t('dashboard.activity_descriptions.wishlist_liked')
    when 'friend_connected'
      t('dashboard.activity_descriptions.friend_connected')
    when 'profile_updated'
      t('dashboard.activity_descriptions.profile_updated')
    when 'wishlist_shared'
      t('dashboard.activity_descriptions.wishlist_shared')
    else
      'performed an action'  # Fallback
    end
  end

  def ensure_dashboard_data
    # This method ensures we always have basic data for API responses
    @dashboard_loaded ||= false
  end
end
