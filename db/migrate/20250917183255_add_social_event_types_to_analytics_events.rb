class AddSocialEventTypesToAnalyticsEvents < ActiveRecord::Migration[8.0]
  def change
    # This migration adds new event types to the existing enum in AnalyticsEvent
    # The actual enum changes will be made in the model file
    # We're just adding a comment here to document the new event types being added:
    #
    # New social event types:
    # - wishlist_liked: 14
    # - wishlist_commented: 15
    # - item_commented: 16
    # - friend_activity_viewed: 17
    # - trending_item_clicked: 18
    # - recommendation_followed: 19
    # - dashboard_viewed: 20
    # - activity_feed_viewed: 21

    # No database changes needed - enums are stored as integers
    # Changes will be made to app/models/analytics_event.rb
  end
end
