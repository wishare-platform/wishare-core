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
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'wishlist_created',
      event_category: 'wishlist',
      event_action: 'create',
      wishlist_name: formData.get('wishlist[name]') || 'Untitled',
      event_type: formData.get('wishlist[event_type]') || 'general',
      visibility: formData.get('wishlist[visibility]') || 'private',
      has_event_date: formData.get('wishlist[event_date]') ? true : false
    });
  }

  // Track wishlist editing
  trackWishlistEdited(event) {
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'wishlist_edited',
      event_category: 'wishlist',
      event_action: 'edit',
      wishlist_name: formData.get('wishlist[name]') || 'Untitled',
      event_type: formData.get('wishlist[event_type]') || 'general',
      visibility: formData.get('wishlist[visibility]') || 'private'
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
      event_category: 'engagement',
      event_action: 'notification_click',
      notification_type: event.params?.notificationType,
      notification_id: event.params?.notificationId
    });
  }

  // Track user registration
  trackUserRegistration(event) {
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'sign_up',
      event_category: 'authentication',
      event_action: 'register',
      method: event.target.querySelector('input[name="user[provider]"]')?.value || 'email',
      has_invitation: formData.get('invitation_token') ? true : false
    });
  }

  // Track user login
  trackUserLogin(event) {
    this.pushToDataLayer({
      event: 'login',
      event_category: 'authentication', 
      event_action: 'sign_in',
      method: event.target.querySelector('input[name="user[provider]"]')?.value || 'email'
    });
  }

  // Track invitation sent
  trackInvitationSent(event) {
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'invitation_sent',
      event_category: 'social',
      event_action: 'invite_friend',
      invitation_type: 'email',
      has_message: formData.get('invitation[message]') ? true : false
    });
  }

  // Track invitation accepted
  trackInvitationAccepted() {
    this.pushToDataLayer({
      event: 'invitation_accepted',
      event_category: 'social',
      event_action: 'accept_invitation'
    });
  }

  // Track wishlist sharing
  trackWishlistShared(event) {
    this.pushToDataLayer({
      event: 'share',
      event_category: 'social',
      event_action: 'share_wishlist',
      content_type: 'wishlist',
      share_method: event.params?.shareMethod || 'link'
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