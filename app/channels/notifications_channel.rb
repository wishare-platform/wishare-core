class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end

  def unsubscribed
    stop_all_streams
  end

  def mark_as_read(data)
    notification = current_user.notifications.find(data["notification_id"])
    notification.update(read: true)

    NotificationsChannel.broadcast_to(
      current_user,
      {
        action: "update_count",
        count: current_user.unread_notifications_count
      }
    )
  end
end
