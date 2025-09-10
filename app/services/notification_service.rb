class NotificationService
  def create_item_purchase_notification(user:, purchaser:, wishlist_item:, wishlist:)
    return unless user.notification_preference&.should_send_email?(:item_purchased)
    
    notification = user.notifications.create!(
      notifiable: wishlist_item,
      notification_type: 'item_purchased',
      data: {
        purchaser_id: purchaser.id,
        purchaser_name: purchaser.display_name,
        item_id: wishlist_item.id,
        item_name: wishlist_item.name,
        wishlist_id: wishlist.id,
        wishlist_name: wishlist.name
      }
    )
    
    # Send email notification if user prefers instant notifications
    if user.notification_preference.digest_frequency == 'instant'
      ItemPurchaseMailer.item_purchased(notification).deliver_later
    end
    
    # Send push notification if user has it enabled
    if user.notification_preference.push_enabled?
      PushNotificationService.new.send_item_purchase_notification(notification)
    end
    
    notification
  end
  
  def create_new_item_notification(wishlist:, item:, connected_users:)
    return if connected_users.empty?
    
    connected_users.each do |connected_user|
      next unless connected_user.notification_preference&.should_send_email?(:new_item_added)
      
      notification = connected_user.notifications.create!(
        notifiable: item,
        notification_type: 'new_item_added',
        data: {
          wishlist_owner_id: wishlist.user.id,
          wishlist_owner_name: wishlist.user.display_name,
          item_id: item.id,
          item_name: item.name,
          wishlist_id: wishlist.id,
          wishlist_name: wishlist.name
        }
      )
      
      # Send email notification if user prefers instant notifications
      if connected_user.notification_preference.digest_frequency == 'instant'
        NewItemMailer.new_item_added(notification).deliver_later
      end
    end
  end
  
  def create_connection_removed_notification(user:, removed_by:, connection:)
    return unless user.notification_preference&.should_send_email?(:connection_removed)
    
    notification = user.notifications.create!(
      notifiable: connection,
      notification_type: 'connection_removed',
      data: {
        removed_by_id: removed_by.id,
        removed_by_name: removed_by.display_name
      }
    )
    
    # Send email notification if user prefers instant notifications
    if user.notification_preference.digest_frequency == 'instant'
      ConnectionMailer.connection_removed(notification).deliver_later
    end
    
    notification
  end
end