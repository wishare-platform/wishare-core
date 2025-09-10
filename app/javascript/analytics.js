// Analytics helper module for tracking events throughout the application

class Analytics {
  constructor() {
    // Ensure dataLayer exists
    window.dataLayer = window.dataLayer || [];
  }
  
  // Push event to dataLayer
  track(eventName, eventData = {}) {
    const data = {
      event: eventName,
      timestamp: new Date().toISOString(),
      ...eventData
    };
    
    // Remove undefined values
    Object.keys(data).forEach(key => {
      if (data[key] === undefined) {
        delete data[key];
      }
    });
    
    window.dataLayer.push(data);
    
    // Debug logging - always log for now
    console.log('Analytics Event:', data);
  }
  
  // Wishlist events
  trackWishlistCreated(wishlistData) {
    this.track('wishlist_created', wishlistData);
  }
  
  trackItemAdded(itemData) {
    this.track('item_added_to_wishlist', itemData);
  }
  
  trackWishlistShared(shareData) {
    this.track('wishlist_shared', shareData);
  }
  
  // Connection events
  trackInvitationSent(invitationData) {
    this.track('invitation_sent', invitationData);
  }
  
  trackInvitationAccepted(connectionData) {
    this.track('invitation_accepted', connectionData);
  }
  
  trackConnectionFormed(connectionData) {
    this.track('user_connected', connectionData);
  }
  
  // Item events
  trackItemPurchased(itemData) {
    this.track('item_purchased_externally', itemData);
  }
  
  // Notification events
  trackNotificationClicked(notificationData) {
    this.track('notification_clicked', notificationData);
  }
  
  // User engagement events
  trackSignUp(userData) {
    this.track('sign_up', userData);
  }
  
  trackLogin(userData) {
    this.track('login', userData);
  }
  
  // Search events
  trackSearch(searchData) {
    this.track('search', searchData);
  }
  
  // Error tracking
  trackError(errorData) {
    this.track('error', {
      error_message: errorData.message,
      error_type: errorData.type,
      error_location: errorData.location
    });
  }
  
  // E-commerce style events for wishlists
  trackViewWishlist(wishlistData) {
    this.track('view_wishlist', wishlistData);
  }
  
  trackViewItem(itemData) {
    this.track('view_item', itemData);
  }
}

// Export singleton instance
const analytics = new Analytics();
export default analytics;

// Also make it available globally for inline scripts
window.WishareAnalytics = analytics;