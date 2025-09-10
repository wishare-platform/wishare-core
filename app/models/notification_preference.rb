class NotificationPreference < ApplicationRecord
  belongs_to :user

  enum :digest_frequency, {
    instant: 0,
    daily: 1,
    weekly: 2,
    never: 3
  }

  validates :user_id, uniqueness: true

  def should_send_email?(notification_type)
    case notification_type.to_sym
    when :invitation_received, :invitation_accepted, :invitation_declined
      email_invitations?
    when :item_purchased
      email_purchases?
    when :new_item_added
      email_new_items?
    when :connection_removed, :wishlist_shared
      email_connections?
    else
      true
    end
  end
end
