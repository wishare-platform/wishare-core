import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="analytics"
export default class extends Controller {
  static values = { 
    event: String,
    category: String,
    action: String,
    label: String,
    value: Number
  }
  
  connect() {
    // Initialize dataLayer if it doesn't exist
    window.dataLayer = window.dataLayer || [];
  }
  
  // Track a custom event
  trackEvent(event) {
    const eventData = {
      event: this.eventValue || event.params?.event || 'custom_event',
      event_category: this.categoryValue || event.params?.category,
      event_action: this.actionValue || event.params?.action,
      event_label: this.labelValue || event.params?.label,
      value: this.valueValue || event.params?.value
    };
    
    // Clean up undefined values
    Object.keys(eventData).forEach(key => {
      if (eventData[key] === undefined) {
        delete eventData[key];
      }
    });
    
    this.pushToDataLayer(eventData);
  }
  
  // Track wishlist creation
  trackWishlistCreated(event) {
    this.pushToDataLayer({
      event: 'wishlist_created',
      wishlist_id: event.params?.wishlistId,
      wishlist_name: event.params?.wishlistName,
      event_type: event.params?.eventType,
      visibility: event.params?.visibility
    });
  }
  
  // Track item added to wishlist
  trackItemAdded(event) {
    this.pushToDataLayer({
      event: 'item_added_to_wishlist',
      wishlist_id: event.params?.wishlistId,
      item_name: event.params?.itemName,
      item_price: event.params?.itemPrice,
      item_priority: event.params?.itemPriority
    });
  }
  
  // Track wishlist shared
  trackWishlistShared(event) {
    this.pushToDataLayer({
      event: 'wishlist_shared',
      wishlist_id: event.params?.wishlistId,
      share_method: event.params?.method // 'link', 'email', 'social'
    });
  }
  
  // Track invitation sent
  trackInvitationSent(event) {
    this.pushToDataLayer({
      event: 'invitation_sent',
      recipient_email: event.params?.recipientEmail // Be careful with PII
    });
  }
  
  // Track invitation accepted
  trackInvitationAccepted(event) {
    this.pushToDataLayer({
      event: 'invitation_accepted',
      connection_id: event.params?.connectionId
    });
  }
  
  // Track item marked as purchased
  trackItemPurchased(event) {
    this.pushToDataLayer({
      event: 'item_purchased_externally',
      wishlist_id: event.params?.wishlistId,
      item_id: event.params?.itemId,
      item_name: event.params?.itemName,
      item_price: event.params?.itemPrice
    });
  }
  
  // Track user connection formed
  trackConnectionFormed(event) {
    this.pushToDataLayer({
      event: 'user_connected',
      connection_id: event.params?.connectionId,
      connection_type: event.params?.connectionType
    });
  }
  
  // Track notification clicked
  trackNotificationClicked(event) {
    this.pushToDataLayer({
      event: 'notification_clicked',
      notification_type: event.params?.notificationType,
      notification_id: event.params?.notificationId
    });
  }
  
  // Track page view with custom parameters
  trackPageView(event) {
    this.pushToDataLayer({
      event: 'page_view',
      page_path: window.location.pathname,
      page_title: document.title,
      user_status: event.params?.userStatus || 'guest',
      content_group: event.params?.contentGroup
    });
  }
  
  // Helper method to push data to dataLayer
  pushToDataLayer(data) {
    if (window.dataLayer) {
      // Add timestamp and user info if available
      data.timestamp = new Date().toISOString();
      
      // Add user ID if element has it (be careful with PII)
      if (this.element.dataset.userId) {
        data.user_id = this.element.dataset.userId;
      }
      
      console.log('Analytics Event:', data); // Debug logging
      window.dataLayer.push(data);
    }
  }
}