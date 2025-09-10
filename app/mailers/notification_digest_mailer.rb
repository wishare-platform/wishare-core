class NotificationDigestMailer < ApplicationMailer
  def daily_digest(user, notifications)
    @user = user
    @notifications = notifications
    @notification_count = @notifications.count

    I18n.with_locale(@user.preferred_locale || I18n.default_locale) do
      mail(
        to: @user.email,
        subject: t("emails.digest.daily.subject", count: @notification_count)
      )
    end
  end

  def weekly_digest(user, notifications)
    @user = user
    @notifications = notifications
    @notification_count = @notifications.count

    I18n.with_locale(@user.preferred_locale || I18n.default_locale) do
      mail(
        to: @user.email,
        subject: t("emails.digest.weekly.subject", count: @notification_count)
      )
    end
  end

  private

  def grouped_notifications
    @grouped_notifications ||= @notifications.group_by(&:notification_type)
  end
  helper_method :grouped_notifications

  def format_timeframe
    case action_name
    when "daily_digest"
      I18n.t("emails.digest.daily.timeframe")
    when "weekly_digest"
      I18n.t("emails.digest.weekly.timeframe")
    end
  end
  helper_method :format_timeframe
end
