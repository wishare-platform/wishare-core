require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "valid notification" do
    notification = build(:notification)
    assert notification.valid?
  end

  test "requires notification_type" do
    notification = build(:notification, notification_type: nil)
    assert_not notification.valid?
  end

  test "unread scope returns only unread notifications" do
    user = create(:user)
    invitation = create(:invitation, sender: create(:user))
    create(:notification, user: user, notifiable: invitation, read: false)
    create(:notification, user: user, notifiable: invitation, read: true)

    assert_equal 1, Notification.unread.count
  end

  test "recent scope orders by created_at desc" do
    user = create(:user)
    invitation = create(:invitation, sender: create(:user))
    old = create(:notification, user: user, notifiable: invitation, created_at: 2.days.ago)
    recent = create(:notification, user: user, notifiable: invitation, created_at: 1.hour.ago)

    assert_equal recent, Notification.recent.first
  end

  test "localized_title returns i18n title for invitation_received" do
    notification = build(:notification, notification_type: :invitation_received)
    assert notification.localized_title.is_a?(String)
    assert notification.localized_title.present?
  end

  test "localized_message interpolates data" do
    notification = build(:notification,
      notification_type: :invitation_received,
      data: { "sender_name" => "Alice" }
    )
    assert_includes notification.localized_message, "Alice"
  end
end
