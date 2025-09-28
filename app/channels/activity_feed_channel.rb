class ActivityFeedChannel < ApplicationCable::Channel
  # Rate limiting: max 20 subscriptions per minute per user (allows for multiple tabs and reconnections)
  SUBSCRIPTION_LIMIT = 20
  SUBSCRIPTION_WINDOW = 1.minute

  def subscribed
    # Rate limiting check
    unless check_subscription_rate_limit
      Rails.logger.warn "ActivityFeedChannel subscription rejected for user #{current_user.id}: Rate limit exceeded"
      reject
      return
    end

    # Set locale from subscription parameters
    set_locale_from_params

    # Subscribe to the user's personalized activity feed
    stream_from "activity_feed_#{current_user.id}"

    # Also subscribe to public activities if user wants to see all content
    stream_from "activity_feed_public" if params[:include_public]

    Rails.logger.info "User #{current_user.id} subscribed to activity feed channel with locale: #{I18n.locale}"
  end

  def unsubscribed
    Rails.logger.info "User #{current_user.id} unsubscribed from activity feed channel"
    stop_all_streams
  end

  def change_feed_type(data)
    # Rate limiting check for feed type changes
    return reject_action('Rate limit exceeded') unless check_action_rate_limit

    # Set locale from subscription parameters
    set_locale_from_params

    # Allow users to switch between different feed types in real-time
    feed_type = data['feed_type']

    # Stop all current streams
    stop_all_streams

    case feed_type
    when 'for_you'
      stream_from "activity_feed_#{current_user.id}"
    when 'friends'
      stream_from "activity_feed_friends_#{current_user.id}"
    when 'following'
      stream_from "activity_feed_following_#{current_user.id}"
    when 'all'
      stream_from "activity_feed_public"
    else
      stream_from "activity_feed_#{current_user.id}"
    end

    Rails.logger.info "User #{current_user.id} switched to #{feed_type} feed with locale: #{I18n.locale}"
  end

  def request_feed_update(data)
    # Rate limiting check for feed update requests
    return reject_action('Rate limit exceeded') unless check_action_rate_limit

    # Set locale from subscription parameters
    set_locale_from_params

    # Manual refresh request from client
    offset = data['offset'] || 0
    limit = [data['limit'] || 20, 50].min # Cap at 50 items per request
    feed_type = data['feed_type'] || 'for_you'

    activities = ActivityFeedService.generate_feed(
      user: current_user,
      feed_type: feed_type,
      limit: limit,
      offset: offset
    )

    # Send the feed data back to the client
    transmit({
      type: 'feed_update',
      activities: render_activities(activities),
      has_more: activities.count == limit
    })
  end

  private

  def set_locale_from_params
    # Use locale from subscription parameters if provided, otherwise fall back to connection locale
    locale = params[:locale] || connection.current_locale
    I18n.locale = locale
    Rails.logger.info "ActivityFeedChannel - Setting locale to: #{I18n.locale}"
  end

  def check_subscription_rate_limit
    # Simple in-memory rate limiting (in production, use Redis)
    cache_key = "activityfeed_sub_#{current_user.id}"
    current_count = Rails.cache.read(cache_key) || 0

    if current_count >= SUBSCRIPTION_LIMIT
      Rails.logger.warn "Subscription rate limit exceeded for user #{current_user.id}"
      return false
    end

    Rails.cache.write(cache_key, current_count + 1, expires_in: SUBSCRIPTION_WINDOW)
    true
  end

  def check_action_rate_limit
    # Rate limit for actions like feed type changes and update requests
    cache_key = "activityfeed_action_#{current_user.id}"
    current_count = Rails.cache.read(cache_key) || 0

    if current_count >= 10 # Max 10 actions per minute
      Rails.logger.warn "Action rate limit exceeded for user #{current_user.id}"
      return false
    end

    Rails.cache.write(cache_key, current_count + 1, expires_in: 1.minute)
    true
  end


  def reject_action(message)
    Rails.logger.warn "ActivityFeedChannel action rejected for user #{current_user.id}: #{message}"
    transmit({
      type: 'error',
      message: message
    })
  end

  def render_activities(activities)
    activities.includes(:actor, :target, :user).map do |activity|
      {
        id: activity.id,
        action_type: activity.action_type,
        action_description: activity.action_description,
        actor: {
          id: activity.actor.id,
          name: activity.actor.name,
          avatar_url: activity.actor.profile_avatar_url
        },
        target: serialize_target(activity.target),
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
  end

  def serialize_target(target)
    return nil unless target

    case target
    when Wishlist
      {
        id: target.id,
        name: target.name,
        type: 'Wishlist',
        url: Rails.application.routes.url_helpers.wishlist_path(locale: I18n.locale, id: target.id),
        cover_image_url: target.cover_image_url,
        visibility: target.visibility,
        event_type: target.event_type
      }
    when WishlistItem
      {
        id: target.id,
        name: target.name,
        type: 'WishlistItem',
        url: Rails.application.routes.url_helpers.wishlist_wishlist_item_path(locale: I18n.locale, wishlist_id: target.wishlist.id, id: target.id),
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
end