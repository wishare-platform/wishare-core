class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  enum :notification_type, {
    invitation_received: 0,
    invitation_accepted: 1,
    invitation_declined: 2,
    item_purchased: 3,
    wishlist_shared: 4,
    new_item_added: 5,
    connection_removed: 6
  }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  validates :notification_type, presence: true

  after_create_commit :broadcast_notification

  def localized_title
    case notification_type.to_sym
    when :invitation_received
      I18n.t("notifications.types.invitation_received.title")
    when :invitation_accepted
      I18n.t("notifications.types.invitation_accepted.title")
    when :invitation_declined
      I18n.t("notifications.types.invitation_declined.title")
    when :item_purchased
      I18n.t("notifications.types.item_purchased.title")
    when :wishlist_shared
      I18n.t("notifications.types.wishlist_shared.title")
    when :new_item_added
      I18n.t("notifications.types.new_item_added.title")
    when :connection_removed
      I18n.t("notifications.types.connection_removed.title")
    else
      title
    end
  end

  def localized_message
    case notification_type.to_sym
    when :invitation_received
      I18n.t("notifications.types.invitation_received.message",
              sender_name: data&.dig("sender_name") || "Unknown")
    when :invitation_accepted
      I18n.t("notifications.types.invitation_accepted.message",
              acceptor_name: data&.dig("acceptor_name") || "Unknown")
    when :invitation_declined
      I18n.t("notifications.types.invitation_declined.message")
    when :item_purchased
      I18n.t("notifications.types.item_purchased.message",
              purchaser_name: data&.dig("purchaser_name") || "Someone",
              item_name: data&.dig("item_name") || "an item")
    when :wishlist_shared
      I18n.t("notifications.types.wishlist_shared.message",
              sharer_name: data&.dig("sharer_name") || "Someone")
    when :new_item_added
      I18n.t("notifications.types.new_item_added.message",
              user_name: data&.dig("user_name") || "Someone",
              item_name: data&.dig("item_name") || "an item")
    when :connection_removed
      I18n.t("notifications.types.connection_removed.message",
              user_name: data&.dig("user_name") || "Someone")
    else
      message
    end
  end

  private

  def broadcast_notification
    NotificationsChannel.broadcast_to(
      user,
      {
        action: "new_notification",
        notification: {
          id: id,
          title: localized_title,
          message: localized_message,
          notification_type: notification_type,
          created_at: created_at,
          read: read,
          data: data
        },
        count: user.unread_notifications_count
      }
    )
  end
end
