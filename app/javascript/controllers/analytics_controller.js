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
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'add_to_wishlist',
      event_category: 'item',
      event_action: 'add_item',
      item_name: formData.get('wishlist_item[name]') || 'Untitled Item',
      item_price: formData.get('wishlist_item[price]') || null,
      item_url: formData.get('wishlist_item[url]') || null,
      priority: formData.get('wishlist_item[priority]') || 'medium',
      has_description: formData.get('wishlist_item[description]') ? true : false,
      has_image: formData.get('wishlist_item[image_url]') ? true : false
    });
  }

  // Track item edited
  trackItemEdited(event) {
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'item_edited', 
      event_category: 'item',
      event_action: 'edit_item',
      item_name: formData.get('wishlist_item[name]') || 'Untitled Item',
      priority: formData.get('wishlist_item[priority]') || 'medium',
      has_price_change: formData.get('wishlist_item[price]') ? true : false
    });
  }

  // Track item removed from wishlist
  trackItemRemoved(event) {
    this.pushToDataLayer({
      event: 'remove_from_wishlist',
      event_category: 'item', 
      event_action: 'remove_item',
      item_id: event.params?.itemId,
      item_name: event.params?.itemName || 'Item',
      removal_reason: 'manual_delete'
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
      method: window.location.href.includes('google') ? 'google' : 'email',
      has_invitation: formData.get('invitation_token') ? true : false
    });
  }

  // Track user login
  trackUserLogin(event) {
    this.pushToDataLayer({
      event: 'login',
      event_category: 'authentication', 
      event_action: 'sign_in',
      method: window.location.href.includes('google') ? 'google' : 'email'
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

  // Track wishlist deletion
  trackWishlistDeleted(event) {
    this.pushToDataLayer({
      event: 'wishlist_deleted',
      event_category: 'wishlist',
      event_action: 'delete',
      wishlist_id: event.params?.wishlistId,
      wishlist_name: event.params?.wishlistName || 'Wishlist',
      items_count: event.params?.itemsCount || 0,
      deletion_method: 'manual'
    });
  }

  // Track wishlist visibility change
  trackVisibilityChanged(event) {
    this.pushToDataLayer({
      event: 'wishlist_visibility_changed',
      event_category: 'wishlist',
      event_action: 'change_visibility',
      old_visibility: event.params?.oldVisibility,
      new_visibility: event.params?.newVisibility
    });
  }

  // Track item marked as purchased
  trackItemPurchased(event) {
    this.pushToDataLayer({
      event: 'purchase_item',
      event_category: 'item',
      event_action: 'mark_purchased',
      item_id: event.params?.itemId,
      item_name: event.params?.itemName || 'Item',
      item_price: event.params?.itemPrice,
      purchased_by: event.params?.purchasedBy || 'owner'
    });
  }

  // Track external product link clicks
  trackExternalLinkClick(event) {
    const link = event.target.closest('a');
    this.pushToDataLayer({
      event: 'click',
      event_category: 'external_link',
      event_action: 'product_link_click',
      link_url: link?.href,
      link_text: link?.textContent?.trim().substring(0, 50),
      item_name: event.params?.itemName,
      outbound: true
    });
  }

  // Track profile updates
  trackProfileUpdate(event) {
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'profile_updated',
      event_category: 'user',
      event_action: 'update_profile',
      has_name_change: formData.get('user[name]') ? true : false,
      has_email_change: formData.get('user[email]') ? true : false,
      has_password_change: formData.get('user[password]') ? true : false
    });
  }

  // Track search actions
  trackSearch(event) {
    const searchTerm = event.target.value.trim();
    if (searchTerm.length > 2) {
      this.pushToDataLayer({
        event: 'search',
        event_category: 'engagement',
        event_action: 'search',
        search_term: searchTerm.toLowerCase().substring(0, 50),
        search_category: event.params?.category || 'general'
      });
    }
  }

  // Track filter usage
  trackFilterUsed(event) {
    this.pushToDataLayer({
      event: 'filter_used',
      event_category: 'engagement',
      event_action: 'apply_filter',
      filter_type: event.params?.filterType,
      filter_value: event.params?.filterValue,
      results_count: event.params?.resultsCount
    });
  }

  // Track notification preferences update
  trackNotificationPreferences(event) {
    const formData = new FormData(event.target);
    this.pushToDataLayer({
      event: 'notification_preferences_updated',
      event_category: 'user',
      event_action: 'update_preferences',
      email_notifications: formData.get('email_notifications') === 'true',
      push_notifications: formData.get('push_notifications') === 'true',
      digest_frequency: formData.get('digest_frequency') || 'weekly'
    });
  }

  // Track connection removal
  trackConnectionRemoved(event) {
    this.pushToDataLayer({
      event: 'connection_removed',
      event_category: 'social',
      event_action: 'remove_connection',
      connection_id: event.params?.connectionId,
      removal_reason: 'manual_disconnect'
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