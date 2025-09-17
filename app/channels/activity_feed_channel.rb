class ActivityFeedChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to the user's personalized activity feed
    stream_from "activity_feed_#{current_user.id}"

    # Also subscribe to public activities if user wants to see all content
    stream_from "activity_feed_public" if params[:include_public]

    Rails.logger.info "User #{current_user.id} subscribed to activity feed channel"
  end

  def unsubscribed
    Rails.logger.info "User #{current_user.id} unsubscribed from activity feed channel"
    stop_all_streams
  end

  def change_feed_type(data)
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

    Rails.logger.info "User #{current_user.id} switched to #{feed_type} feed"
  end

  def request_feed_update(data)
    # Manual refresh request from client
    offset = data['offset'] || 0
    limit = data['limit'] || 20
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

  def render_activities(activities)
    activities.includes(:actor, :target, :user).map do |activity|
      {
        id: activity.id,
        action_type: activity.action_type,
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
        time_ago: time_ago_in_words(activity.occurred_at),
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
end