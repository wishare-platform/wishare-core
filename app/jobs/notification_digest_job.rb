class NotificationDigestJob < ApplicationJob
  queue_as :default

  def perform(frequency = 'daily')
    case frequency
    when 'daily'
      process_daily_digests
    when 'weekly'
      process_weekly_digests
    else
      Rails.logger.error "Invalid digest frequency: #{frequency}"
    end
  end

  private

  def process_daily_digests
    users_for_daily_digest.find_each do |user|
      notifications = unprocessed_notifications_for_user(user, 1.day.ago)
      next if notifications.empty?

      NotificationDigestMailer.daily_digest(user, notifications).deliver_now
      mark_notifications_as_processed(notifications, 'daily')
    end
  end

  def process_weekly_digests
    users_for_weekly_digest.find_each do |user|
      notifications = unprocessed_notifications_for_user(user, 1.week.ago)
      next if notifications.empty?

      NotificationDigestMailer.weekly_digest(user, notifications).deliver_now
      mark_notifications_as_processed(notifications, 'weekly')
    end
  end

  def users_for_daily_digest
    User.joins(:notification_preference)
        .where(notification_preferences: { digest_frequency: 'daily' })
  end

  def users_for_weekly_digest
    User.joins(:notification_preference)
        .where(notification_preferences: { digest_frequency: 'weekly' })
  end

  def unprocessed_notifications_for_user(user, since)
    user.notifications
        .where(created_at: since..Time.current)
        .where(digest_processed_at: nil)
        .order(created_at: :desc)
  end

  def mark_notifications_as_processed(notifications, frequency)
    notifications.update_all(
      digest_processed_at: Time.current,
      digest_frequency_sent: frequency
    )
  end
end