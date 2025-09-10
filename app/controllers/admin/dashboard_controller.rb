class Admin::DashboardController < Admin::BaseController
  def index
    @platform_stats = platform_statistics
    @growth_metrics = growth_metrics
    @recent_activities = recent_activities
    @user_analytics = user_analytics_summary
  end

  private

  def platform_statistics
    {
      total_users: User.count,
      active_users_30d: User.joins(:user_analytic)
                           .where('user_analytics.last_activity_at > ?', 30.days.ago)
                           .count,
      total_wishlists: Wishlist.count,
      total_connections: Connection.accepted_connections.count,
      total_items: WishlistItem.count,
      total_purchases: WishlistItem.where(status: :purchased).count
    }
  end

  def growth_metrics
    current_month = Date.current.beginning_of_month
    last_month = 1.month.ago.beginning_of_month
    
    {
      new_users_this_month: User.where(created_at: current_month..).count,
      new_users_last_month: User.where(created_at: last_month..current_month).count,
      wishlists_this_month: Wishlist.where(created_at: current_month..).count,
      connections_this_month: Connection.accepted_connections
                                       .where(created_at: current_month..).count
    }
  end

  def recent_activities
    AnalyticsEvent.recent
                  .includes(:user)
                  .limit(20)
                  .select(:id, :user_id, :event_type, :created_at, :metadata)
  end

  def user_analytics_summary
    UserAnalytic.joins(:user)
                .includes(:user)
                .limit(10)
                .sort_by { |ua| -ua.engagement_score }
  end
end