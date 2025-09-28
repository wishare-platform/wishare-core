import { Controller } from "@hotwired/stimulus"

// Mobile Performance Optimization Controller
export default class extends Controller {
  static values = {
    authCheckEnabled: { type: Boolean, default: true },
    authCheckInterval: { type: Number, default: 300000 } // 5 minutes
  }

  connect() {
    this.retryCount = 0
    this.maxRetries = 3
    this.authCheckTimer = null
    this.isMobileApp = this.detectMobileApp()

    this.optimizeForMobile()
    this.setupPerformanceMonitoring()
    this.addLoadingStates()
    this.setupAuthenticationMonitoring()

    console.log('MobilePerformance: Controller connected, mobile app:', this.isMobileApp)
  }

  disconnect() {
    if (this.authCheckTimer) {
      clearInterval(this.authCheckTimer)
    }
    console.log('MobilePerformance: Controller disconnected')
  }

  detectMobileApp() {
    return navigator.userAgent.includes('Hotwire Native') ||
           window.webkit?.messageHandlers?.authBridge ||
           document.documentElement.classList.contains('mobile-app') ||
           window.location.search.includes('mobile=true')
  }

  setupAuthenticationMonitoring() {
    if (!this.authCheckEnabledValue) {
      console.log('MobilePerformance: Auth monitoring disabled')
      return
    }

    // Enable auth monitoring for both mobile and web
    console.log('MobilePerformance: Setting up auth monitoring for', this.isMobileApp ? 'mobile app' : 'web browser')

    // Start periodic authentication checks (more frequent for web)
    const checkInterval = this.isMobileApp ? this.authCheckIntervalValue : 120000 // 2 min for web, 5 min for mobile
    this.authCheckTimer = setInterval(() => {
      this.checkAuthenticationStatus()
    }, checkInterval)

    // Check auth on visibility change
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        console.log('MobilePerformance: App became visible, checking auth')
        this.checkAuthenticationStatus()
      }
    })
  }

  async checkAuthenticationStatus() {
    try {
      const response = await fetch('/mobile/auth/session_check', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-Hotwire-Native': 'true'
        },
        credentials: 'same-origin'
      })

      if (response.status === 401 || response.status === 403) {
        this.handleAuthenticationExpired()
        return
      }

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()

      if (data.status === 'authenticated') {
        this.retryCount = 0 // Reset on success
        this.notifyNativeApp('authentication_success', data)
      } else {
        this.handleAuthenticationExpired()
      }

    } catch (error) {
      console.error('MobilePerformance: Auth check failed:', error)
      this.retryCount++

      if (this.retryCount >= this.maxRetries) {
        console.warn('MobilePerformance: Max auth retries reached')
        this.handleAuthenticationExpired()
      }
    }
  }

  handleAuthenticationExpired() {
    console.warn('MobilePerformance: Authentication expired')

    // Stop auth checking
    if (this.authCheckTimer) {
      clearInterval(this.authCheckTimer)
      this.authCheckTimer = null
    }

    // Notify native app
    this.notifyNativeApp('authentication_required', {
      message: 'Your session has expired. Please sign in again.',
      sign_in_url: '/users/sign_in'
    })

    // Show web fallback message
    this.showAuthenticationBanner()
  }

  notifyNativeApp(type, data) {
    if (window.webkit?.messageHandlers?.authBridge) {
      window.webkit.messageHandlers.authBridge.postMessage({
        type: type,
        data: data
      })
      console.log('MobilePerformance: Notified native app:', type)
    } else if (window.WishareAuth) {
      switch (type) {
        case 'authentication_required':
          window.WishareAuth.reportAuthenticationRequired()
          break
        case 'authentication_success':
          window.WishareAuth.reportAuthenticationSuccess(data)
          break
        case 'authentication_error':
          window.WishareAuth.reportAuthenticationError(data.message)
          break
      }
    } else {
      console.log('MobilePerformance: No native bridge available for:', type)
    }
  }

  showAuthenticationBanner() {
    // Remove existing banner
    const existingBanner = document.getElementById('mobile-auth-banner')
    if (existingBanner) {
      existingBanner.remove()
    }

    // Create new banner with better styling for web
    const banner = document.createElement('div')
    banner.id = 'mobile-auth-banner'
    banner.className = 'fixed top-0 left-0 right-0 bg-red-500 text-white p-4 text-center z-50 shadow-lg'
    banner.innerHTML = `
      <div class="flex items-center justify-center gap-2 text-sm">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>
        </svg>
        <span>Your session has expired.</span>
        <a href="/users/sign_in" class="underline font-medium hover:no-underline transition-all duration-200">Sign In Again</a>
        <button onclick="this.parentElement.parentElement.remove()" class="ml-2 text-white hover:text-gray-200">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
          </svg>
        </button>
      </div>
    `

    document.body.prepend(banner)

    // Auto-hide after 15 seconds (longer for web users to read)
    setTimeout(() => {
      if (banner.parentNode) {
        banner.remove()
      }
    }, 15000)

    // Also trigger activity feed to show auth error
    const activityFeed = document.querySelector('[data-controller="activity-feed"]')
    if (activityFeed && activityFeed._stimulusControllers) {
      const controller = activityFeed._stimulusControllers.find(c => c.identifier === 'activity-feed')
      if (controller) {
        controller.handleAuthenticationError()
      }
    }
  }

  // Public method to restart auth monitoring (called after successful login)
  restartAuthMonitoring() {
    if (this.authCheckEnabledValue && !this.authCheckTimer) {
      console.log('MobilePerformance: Restarting auth monitoring')
      this.retryCount = 0
      const checkInterval = this.isMobileApp ? this.authCheckIntervalValue : 120000
      this.authCheckTimer = setInterval(() => {
        this.checkAuthenticationStatus()
      }, checkInterval)
    }
  }

  // Public method to handle sign out
  handleSignOut() {
    console.log('MobilePerformance: Handling sign out')
    if (this.authCheckTimer) {
      clearInterval(this.authCheckTimer)
      this.authCheckTimer = null
    }
    this.notifyNativeApp('logout', {})
  }

  optimizeForMobile() {
    // Reduce animation on lower-end devices
    this.optimizeAnimations()

    // Optimize scrolling performance
    this.optimizeScrolling()

    // Preload critical resources
    this.preloadCriticalResources()

    // Setup viewport optimizations
    this.setupViewportOptimizations()
  }

  optimizeAnimations() {
    // Detect if device prefers reduced motion
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

    if (prefersReducedMotion) {
      document.documentElement.style.setProperty('--animation-duration', '0.01ms')
      document.documentElement.style.setProperty('--transition-duration', '0.01ms')
    }

    // Disable complex animations on slower devices
    if (this.isLowEndDevice()) {
      document.body.classList.add('reduce-animations')
    }
  }

  optimizeScrolling() {
    // Add passive listeners for better scroll performance
    document.addEventListener('touchstart', this.handleTouchStart.bind(this), { passive: true })
    document.addEventListener('touchmove', this.handleTouchMove.bind(this), { passive: true })

    // Implement virtual scrolling for long lists
    this.setupVirtualScrolling()
  }

  preloadCriticalResources() {
    // Preload next likely pages
    const preloadUrls = [
      '/wishlists',
      '/connections',
      '/users/edit'
    ]

    // Use requestIdleCallback to preload during idle time
    if ('requestIdleCallback' in window) {
      requestIdleCallback(() => {
        preloadUrls.forEach(url => {
          const link = document.createElement('link')
          link.rel = 'prefetch'
          link.href = url
          document.head.appendChild(link)
        })
      })
    }
  }

  setupViewportOptimizations() {
    // Dynamic viewport height for mobile browsers
    const setViewportHeight = () => {
      const vh = window.innerHeight * 0.01
      document.documentElement.style.setProperty('--vh', `${vh}px`)
    }

    setViewportHeight()
    window.addEventListener('resize', setViewportHeight)
    window.addEventListener('orientationchange', setViewportHeight)
  }

  setupVirtualScrolling() {
    const lists = document.querySelectorAll('[data-virtual-scroll]')

    lists.forEach(list => {
      const items = Array.from(list.children)
      const itemHeight = 80 // Approximate item height
      const visibleItems = Math.ceil(window.innerHeight / itemHeight) + 2

      if (items.length > visibleItems) {
        this.implementVirtualScroll(list, items, itemHeight, visibleItems)
      }
    })
  }

  implementVirtualScroll(container, items, itemHeight, visibleItems) {
    let scrollTop = 0
    let startIndex = 0

    const updateVisibleItems = () => {
      const newStartIndex = Math.floor(scrollTop / itemHeight)
      const endIndex = Math.min(newStartIndex + visibleItems, items.length)

      if (newStartIndex !== startIndex) {
        startIndex = newStartIndex

        // Hide all items
        items.forEach(item => item.style.display = 'none')

        // Show visible items
        for (let i = startIndex; i < endIndex; i++) {
          if (items[i]) {
            items[i].style.display = 'block'
            items[i].style.transform = `translateY(${i * itemHeight}px)`
          }
        }
      }
    }

    container.addEventListener('scroll', (e) => {
      scrollTop = e.target.scrollTop
      requestAnimationFrame(updateVisibleItems)
    }, { passive: true })

    // Initial render
    updateVisibleItems()
  }

  setupPerformanceMonitoring() {
    // Monitor frame rate
    this.monitorFrameRate()

    // Monitor memory usage (if available)
    this.monitorMemoryUsage()

    // Monitor user interactions
    this.monitorInteractions()
  }

  monitorFrameRate() {
    let frames = 0
    let lastTime = performance.now()

    const measureFPS = () => {
      frames++
      const currentTime = performance.now()

      if (currentTime >= lastTime + 1000) {
        const fps = Math.round((frames * 1000) / (currentTime - lastTime))

        // Adjust performance based on FPS
        if (fps < 30) {
          document.body.classList.add('low-performance')
        } else {
          document.body.classList.remove('low-performance')
        }

        frames = 0
        lastTime = currentTime
      }

      requestAnimationFrame(measureFPS)
    }

    measureFPS()
  }

  monitorMemoryUsage() {
    if ('memory' in performance) {
      const checkMemory = () => {
        const memory = performance.memory
        const usedMB = memory.usedJSHeapSize / 1048576
        const totalMB = memory.totalJSHeapSize / 1048576

        // If memory usage is high, trigger cleanup
        if (usedMB / totalMB > 0.8) {
          this.performCleanup()
        }
      }

      setInterval(checkMemory, 30000) // Check every 30 seconds
    }
  }

  monitorInteractions() {
    let interactionCount = 0
    const interactions = ['click', 'touchstart', 'scroll']

    interactions.forEach(event => {
      document.addEventListener(event, () => {
        interactionCount++

        // Optimize after high interaction periods
        if (interactionCount > 100) {
          this.performOptimizations()
          interactionCount = 0
        }
      }, { passive: true })
    })
  }

  addLoadingStates() {
    // Add loading states to all buttons and forms
    const buttons = document.querySelectorAll('button[type="submit"], a[data-loading]')

    buttons.forEach(button => {
      button.addEventListener('click', () => {
        if (!button.disabled) {
          this.showLoadingState(button)
        }
      })
    })
  }

  showLoadingState(element) {
    const originalContent = element.innerHTML
    element.setAttribute('data-original-content', originalContent)
    element.disabled = true

    element.innerHTML = `
      <svg class="animate-spin w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
      </svg>
      Loading...
    `

    // Auto-restore after 5 seconds if no navigation occurs
    setTimeout(() => {
      if (element.hasAttribute('data-original-content')) {
        element.innerHTML = element.getAttribute('data-original-content')
        element.disabled = false
        element.removeAttribute('data-original-content')
      }
    }, 5000)
  }

  isLowEndDevice() {
    // Heuristics to detect low-end devices
    const connection = navigator.connection || navigator.mozConnection || navigator.webkitConnection
    const cores = navigator.hardwareConcurrency || 2
    const memory = navigator.deviceMemory || 4

    return (
      (connection && connection.effectiveType === 'slow-2g') ||
      (connection && connection.effectiveType === '2g') ||
      cores < 4 ||
      memory < 4
    )
  }

  performCleanup() {
    // Remove unused event listeners
    // Clear cached data
    // Garbage collect if possible
    console.log('Performing performance cleanup...')
  }

  performOptimizations() {
    // Debounce expensive operations
    // Batch DOM updates
    // Reduce animation complexity
    console.log('Applying performance optimizations...')
  }

  handleTouchStart(e) {
    // Add visual feedback
    if (e.target.closest('button, a, [role="button"]')) {
      e.target.style.opacity = '0.7'
    }
  }

  handleTouchMove(e) {
    // Reset visual feedback on move
    if (e.target.closest('button, a, [role="button"]')) {
      e.target.style.opacity = ''
    }
  }
}