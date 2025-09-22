# Mobile-specific optimization service for Wishare
class MobileOptimizationService
  include ActiveSupport::Benchmarkable

  MOBILE_CACHE_DURATION = 1.hour
  MOBILE_BATCH_SIZE = 50

  def self.optimized_user_feed(user, limit: 20, offset: 0)
    cache_key = "mobile_feed_#{user.id}_#{limit}_#{offset}"

    Rails.cache.fetch(cache_key, expires_in: MOBILE_CACHE_DURATION) do
      benchmark "Mobile Feed Query for User #{user.id}" do
        # Single optimized query for mobile feed
        friend_ids = get_cached_friend_ids(user)

        Wishlist.where(
          "(user_id = ? AND visibility IN (?)) OR " \
          "(user_id IN (?) AND visibility IN (?)) OR " \
          "(visibility = ?)",
          user.id, [:private_list, :partner_only, :publicly_visible],
          friend_ids, [:partner_only, :publicly_visible],
          :publicly_visible
        ).includes(
          :user,
          wishlist_items: [:purchased_by, image_attachment: :blob]
        ).order(updated_at: :desc)
         .limit(limit)
         .offset(offset)
         .to_a
      end
    end
  end

  def self.optimized_wishlist_details(wishlist_id, user)
    cache_key = "mobile_wishlist_#{wishlist_id}_#{user.id}"

    Rails.cache.fetch(cache_key, expires_in: MOBILE_CACHE_DURATION) do
      benchmark "Mobile Wishlist Details #{wishlist_id}" do
        Wishlist.includes(
          :user,
          wishlist_items: [
            :purchased_by,
            image_attachment: { blob: :variant_records }
          ]
        ).find(wishlist_id)
      end
    end
  end

  def self.batch_load_users(user_ids)
    return {} if user_ids.empty?

    cache_key = "mobile_users_#{user_ids.sort.join('_')}"

    Rails.cache.fetch(cache_key, expires_in: MOBILE_CACHE_DURATION) do
      User.where(id: user_ids).index_by(&:id)
    end
  end

  def self.optimized_item_search(query, user, limit: 20)
    cache_key = "mobile_search_#{Digest::MD5.hexdigest(query)}_#{user.id}_#{limit}"

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      benchmark "Mobile Item Search: #{query}" do
        friend_ids = get_cached_friend_ids(user)

        WishlistItem.joins(:wishlist)
                   .where(wishlists: {
                     user_id: [user.id] + friend_ids,
                     visibility: [:partner_only, :publicly_visible]
                   })
                   .where("wishlist_items.name ILIKE ? OR wishlist_items.description ILIKE ?",
                          "%#{query}%", "%#{query}%")
                   .includes(
                     :wishlist,
                     image_attachment: { blob: :variant_records }
                   )
                   .limit(limit)
                   .to_a
      end
    end
  end

  def self.preload_mobile_assets(user)
    # Preload critical data for mobile offline capability
    Rails.cache.write_multi({
      "mobile_user_profile_#{user.id}" => serialize_user_profile(user),
      "mobile_user_wishlists_#{user.id}" => serialize_user_wishlists(user),
      "mobile_recent_activities_#{user.id}" => serialize_recent_activities(user)
    }, expires_in: MOBILE_CACHE_DURATION)
  end

  def self.mobile_analytics_batch(events)
    # Batch analytics events for mobile to reduce API calls
    return if events.empty?

    AnalyticsEvent.insert_all(
      events.map do |event|
        event.merge(
          created_at: Time.current,
          updated_at: Time.current
        )
      end
    )
  end

  private

  def self.get_cached_friend_ids(user)
    Rails.cache.fetch("mobile_friends_#{user.id}", expires_in: MOBILE_CACHE_DURATION) do
      connections = user.connections.accepted.includes(:partner) +
                   user.inverse_connections.accepted.includes(:user)
      connections.map { |c| c.other_user(user).id }
    end
  end

  def self.serialize_user_profile(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      profile_picture_url: user.profile_avatar_url,
      wishlists_count: user.wishlists_count,
      connections_count: user.connections_count,
      preferred_currency: user.preferred_currency,
      preferred_language: user.preferred_language
    }
  end

  def self.serialize_user_wishlists(user)
    user.wishlists.includes(:wishlist_items).map do |wishlist|
      {
        id: wishlist.id,
        name: wishlist.name,
        description: wishlist.description,
        items_count: wishlist.wishlist_items.count,
        cover_image_url: wishlist.cover_image_url,
        event_type: wishlist.event_type,
        event_date: wishlist.event_date,
        updated_at: wishlist.updated_at.iso8601
      }
    end
  end

  def self.serialize_recent_activities(user)
    ActivityFeedService.get_user_activities(user: user, limit: 50).map do |activity|
      {
        id: activity.id,
        action_type: activity.action_type,
        actor_name: activity.actor.name,
        target_type: activity.target_type,
        target_name: activity.target&.name,
        occurred_at: activity.occurred_at.iso8601
      }
    end
  end

  def self.benchmark(message, &block)
    if Rails.env.development?
      result = nil
      time = Benchmark.measure { result = block.call }
      Rails.logger.info "📱 Mobile Optimization - #{message}: #{time.real.round(2)}ms"
      result
    else
      block.call
    end
  end
end