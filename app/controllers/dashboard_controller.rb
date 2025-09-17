class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user

    # Track dashboard view for analytics
    ActivityTrackerService.track_dashboard_viewed(
      user: current_user,
      request: request
    )

    # Pre-load data for efficient sidebar rendering
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
  end
end
