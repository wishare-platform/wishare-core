// Initialize GTM only if consent exists, otherwise prepare for later loading
document.addEventListener('DOMContentLoaded', function() {
  // Ensure dataLayer exists
  window.dataLayer = window.dataLayer || [];
  
  // Only track page views if we have GTM loaded (meaning consent was given)
  if (!window.gtmPendingConsent) {
    // Track initial page view with enhanced data
    window.dataLayer.push({
      event: 'page_view_enhanced',
      page_path: window.location.pathname,
      page_title: document.title,
      page_location: window.location.href,
      page_referrer: document.referrer,
      user_type: document.body.dataset.userType || 'guest',
      timestamp: new Date().toISOString()
    });
    
    console.log('GTM Initialized - Page View Tracked:', {
      path: window.location.pathname,
      title: document.title
    });
  } else {
    console.log('GTM Pending Consent - No tracking until consent given');
  }
});

// Track Turbo page changes (for Rails Turbo) - only if consent given
document.addEventListener('turbo:load', function() {
  if (window.dataLayer && !window.gtmPendingConsent) {
    window.dataLayer.push({
      event: 'turbo_page_view',
      page_path: window.location.pathname,
      page_title: document.title,
      page_location: window.location.href,
      timestamp: new Date().toISOString()
    });
    
    console.log('Turbo Page Change Tracked:', window.location.pathname);
  }
});