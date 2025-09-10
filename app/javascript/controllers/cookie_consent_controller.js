import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cookie-consent"
export default class extends Controller {
  static targets = ["banner", "form", "analyticsToggle", "marketingToggle", "functionalToggle"]
  static values = { 
    showBanner: Boolean,
    hasConsent: Boolean,
    consentUrl: String
  }
  
  connect() {
    // Check if we need to show the banner
    if (this.showBannerValue && !this.hasConsentValue) {
      this.showBanner()
    }
    
    // Listen for consent changes
    this.element.addEventListener("consentGranted", this.handleConsentGranted.bind(this))
  }
  
  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
      this.bannerTarget.classList.add("animate-slide-up")
    }
  }
  
  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("animate-slide-down")
      setTimeout(() => {
        this.bannerTarget.classList.add("hidden")
      }, 300)
    }
  }
  
  // Accept essential cookies only
  acceptEssential(event) {
    event.preventDefault()
    this.submitConsent({
      analytics_enabled: false,
      marketing_enabled: false,
      functional_enabled: true
    })
  }
  
  // Accept all cookies
  acceptAll(event) {
    event.preventDefault()
    this.submitConsent({
      analytics_enabled: true,
      marketing_enabled: true,
      functional_enabled: true
    })
  }
  
  // Show detailed preferences
  showPreferences(event) {
    event.preventDefault()
    if (this.hasFormTarget) {
      this.formTarget.classList.remove("hidden")
      this.bannerTarget.classList.add("hidden")
    }
  }
  
  // Submit custom preferences
  submitPreferences(event) {
    event.preventDefault()
    
    const formData = {
      analytics_enabled: this.analyticsToggleTarget.checked,
      marketing_enabled: this.marketingToggleTarget.checked,
      functional_enabled: this.functionalToggleTarget.checked
    }
    
    this.submitConsent(formData)
  }
  
  // Submit consent to server
  async submitConsent(preferences) {
    console.log('Submitting consent with preferences:', preferences)
    try {
      // Convert preferences to form data
      const formData = new FormData()
      formData.append('analytics_enabled', preferences.analytics_enabled)
      formData.append('marketing_enabled', preferences.marketing_enabled)  
      formData.append('functional_enabled', preferences.functional_enabled)
      
      const response = await fetch(this.consentUrlValue || '/cookie-consent', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        },
        body: formData
      })
      
      console.log('Consent response status:', response.status)
      const data = await response.json()
      console.log('Consent response data:', data)
      
      if (data.success) {
        // Update analytics consent
        this.updateAnalyticsConsent(preferences.analytics_enabled)
        
        // Hide banner
        this.hideBanner()
        
        // Store consent in localStorage for quick access
        localStorage.setItem('cookie_consent', JSON.stringify({
          ...preferences,
          timestamp: Date.now(),
          version: '1.0'
        }))
        
        // Dispatch custom event
        this.element.dispatchEvent(new CustomEvent("consentGranted", {
          detail: { preferences: preferences, response: data }
        }))
        
        // Show success message
        this.showNotification('Cookie preferences saved successfully', 'success')
        
        // Reload page to apply changes
        setTimeout(() => {
          window.location.reload()
        }, 1000)
        
      } else {
        this.showNotification('Failed to save cookie preferences', 'error')
        console.error('Cookie consent error:', data.errors)
      }
    } catch (error) {
      console.error('Cookie consent submission failed:', error)
      this.showNotification('Failed to save cookie preferences', 'error')
    }
  }
  
  // Update GTM analytics consent
  updateAnalyticsConsent(enabled) {
    if (enabled && window.gtmPendingConsent && window.gtmId) {
      // Load GTM dynamically after consent
      this.loadGTM(window.gtmId)
      window.gtmPendingConsent = false
    }
    
    if (window.dataLayer) {
      window.dataLayer.push({
        'event': 'consent_update',
        'analytics_enabled': enabled,
        'timestamp': new Date().toISOString()
      })
    }
    
    // Update global analytics flag
    window.WishareAnalytics = window.WishareAnalytics || {}
    window.WishareAnalytics.consentGiven = enabled
    
    console.log('Analytics consent updated:', enabled)
  }
  
  // Dynamically load GTM
  loadGTM(gtmId) {
    // Initialize GTM
    window.dataLayer.push({'gtm.start': new Date().getTime(), event:'gtm.js'});
    
    // Load GTM script
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtm.js?id=${gtmId}`;
    document.head.appendChild(script);
    
    // Add noscript iframe for no-JS users
    const noscript = document.createElement('noscript');
    const iframe = document.createElement('iframe');
    iframe.src = `https://www.googletagmanager.com/ns.html?id=${gtmId}`;
    iframe.height = "0";
    iframe.width = "0";
    iframe.style.display = "none";
    iframe.style.visibility = "hidden";
    noscript.appendChild(iframe);
    document.body.insertBefore(noscript, document.body.firstChild);
    
    console.log('GTM loaded dynamically:', gtmId);
  }
  
  // Handle consent granted event
  handleConsentGranted(event) {
    console.log('Consent granted:', event.detail)
    
    // Start tracking if analytics enabled
    if (event.detail.preferences.analytics_enabled) {
      this.initializeAnalytics()
    }
  }
  
  // Initialize analytics after consent
  initializeAnalytics() {
    // Track consent given
    if (window.WishareAnalytics) {
      window.WishareAnalytics.track('consent_given', {
        analytics: true,
        consent_version: '1.0'
      })
    }
  }
  
  // Show notification
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg transition-all duration-300 ${
      type === 'success' ? 'bg-green-500 text-white' : 
      type === 'error' ? 'bg-red-500 text-white' : 
      'bg-blue-500 text-white'
    }`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(-10px)'
    }, 100)
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.style.opacity = '0'
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }
  
  // Check if consent is needed (can be called from other controllers)
  static needsConsent() {
    const stored = localStorage.getItem('cookie_consent')
    if (!stored) return true
    
    try {
      const consent = JSON.parse(stored)
      // Check if consent is less than 1 year old
      const oneYear = 365 * 24 * 60 * 60 * 1000
      return (Date.now() - consent.timestamp) > oneYear
    } catch (error) {
      return true
    }
  }
}