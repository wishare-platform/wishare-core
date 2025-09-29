class DashboardDataService
  def initialize(user)
    @user = user
  end

  def call
    {
      user_stats: calculate_user_stats,
      pending_connections: load_pending_connections,
      recent_notifications: load_recent_notifications,
      friends: load_friends,
      upcoming_events: load_upcoming_events,
      recent_items: load_recent_items,
      budget_items: load_budget_items,
      trending_items: load_trending_items,
      featured_wishlists: load_featured_wishlists
    }
  end

  private

  def accepted_connections
    @accepted_connections ||= @user.all_connections.accepted_connections
  end

  def friend_ids
    @friend_ids ||= accepted_connections.map { |c| c.other_user(@user).id }
  end

  def calculate_user_stats
    Rails.cache.fetch("user_stats_#{@user.id}", expires_in: 5.minutes) do
      {
        wishlists_count: @user.wishlists.count,
        items_count: @user.wishlists.joins(:wishlist_items).count,
        friends_count: accepted_connections.count,
        pending_invitations: @user.all_connections.where(status: 'pending').count
      }
    end
  end

  def load_pending_connections
    @user.all_connections
         .where(status: 'pending')
         .includes(:user, :partner)
         .order(created_at: :desc)
         .limit(3)
  end

  def load_recent_notifications
    @user.notifications.unread
         .order(created_at: :desc)
         .limit(5)
  end

  def load_friends
    accepted_connections.includes(user: :avatar_attachment, partner: :avatar_attachment).limit(8)
  end

  def load_upcoming_events
    Wishlist.where(user_id: [@user.id] + friend_ids)
            .where.not(event_date: nil)
            .where('event_date >= ? AND event_date <= ?', Date.today, 30.days.from_now)
            .includes(user: :avatar_attachment)
            .order(event_date: :asc)
            .limit(5)
  end

  def load_recent_items
    return [] if friend_ids.empty?

    WishlistItem.joins(:wishlist)
                .where(wishlists: { user_id: friend_ids, visibility: ['friends', 'public'] })
                .where(purchased_by_id: nil)
                .includes(:wishlist => :user)
                .order(created_at: :desc)
                .limit(5)
  end

  def load_budget_items
    return [] if friend_ids.empty?

    WishlistItem.joins(:wishlist)
                .where(wishlists: { user_id: friend_ids, visibility: ['friends', 'public'] })
                .where(purchased_by_id: nil)
                .where('price < ?', 25)
                .includes(:wishlist => :user)
                .order(created_at: :desc)
                .limit(5)
  end

  def load_trending_items
    return [] if friend_ids.empty?

    WishlistItem.joins(:wishlist)
                .where(wishlists: { user_id: friend_ids, visibility: ['friends', 'public'] })
                .where(purchased_by_id: nil)
                .includes(:wishlist => :user)
                .order(created_at: :desc) # TODO: Replace with actual view/popularity metrics
                .limit(5)
  end

  def load_featured_wishlists
    my_wishlists = @user.wishlists.includes(:wishlist_items, cover_image_attachment: :blob)
                        .order(updated_at: :desc)
                        .limit(2)

    friends_wishlists = if friend_ids.any?
                         Wishlist.where(user_id: friend_ids, visibility: ['friends', 'public'])
                                 .includes(:user, :wishlist_items, cover_image_attachment: :blob)
                                 .order(updated_at: :desc)
                                 .limit(4)
                       else
                         []
                       end

    [my_wishlists, friends_wishlists].flatten.first(4)
  end
end
