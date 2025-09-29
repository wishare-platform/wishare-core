import { Controller } from "@hotwired/stimulus"

// Web Error Handler Controller for browser-specific error handling
export default class extends Controller {
  static targets = ["loadingStates"]

  connect() {
    this.setupGlobalErrorHandling()
    this.setupNetworkErrorDetection()
    console.log('WebErrorHandler: Connected')
  }

  setupGlobalErrorHandling() {
    // Handle global authentication errors
    document.addEventListener('wishare:authentication-error', (event) => {
      this.handleAuthenticationError(event.detail)
    })

    // Handle general application errors
    document.addEventListener('wishare:application-error', (event) => {
      this.handleApplicationError(event.detail)
    })

    // Handle network connectivity issues
    window.addEventListener('online', () => {
      this.handleNetworkRestore()
    })

    window.addEventListener('offline', () => {
      this.handleNetworkLoss()
    })
  }

  setupNetworkErrorDetection() {
    // Monitor fetch failures for network issues
    const originalFetch = window.fetch
    window.fetch = async (...args) => {
      try {
        const response = await originalFetch(...args)

        // Check for authentication errors
        if (response.status === 401 || response.status === 403) {
          console.warn('WebErrorHandler: Authentication error detected')
          document.dispatchEvent(new CustomEvent('wishare:authentication-error', {
            detail: {
              url: args[0],
              status: response.status,
              statusText: response.statusText
            }
          }))
        }

        return response
      } catch (error) {
        // Network error
        console.error('WebErrorHandler: Network error detected', error)
        document.dispatchEvent(new CustomEvent('wishare:application-error', {
          detail: {
            type: 'network',
            message: 'Network connection failed',
            error: error
          }
        }))
        throw error
      }
    }
  }

  handleAuthenticationError(detail) {
    console.log('WebErrorHandler: Handling authentication error', detail)

    // Hide all loading states
    this.hideAllLoadingStates()

    // Show authentication error message
    this.showAuthenticationErrorState()

    // Stop any ongoing background processes
    this.stopBackgroundProcesses()
  }

  handleApplicationError(detail) {
    console.log('WebErrorHandler: Handling application error', detail)

    // Hide loading states
    this.hideAllLoadingStates()

    // Show appropriate error message
    if (detail.type === 'network') {
      this.showNetworkErrorState()
    } else {
      this.showGenericErrorState(detail.message)
    }
  }

  handleNetworkLoss() {
    console.log('WebErrorHandler: Network connection lost')
    this.showNetworkOfflineState()
  }

  handleNetworkRestore() {
    console.log('WebErrorHandler: Network connection restored')
    this.hideNetworkOfflineState()
    // Automatically retry loading
    this.retryFailedOperations()
  }

  hideAllLoadingStates() {
    // Hide activity feed loading
    const activityLoading = document.querySelector('[data-activity-feed-target="loadingState"]')
    if (activityLoading) {
      activityLoading.classList.add('hidden')
    }

    // Hide any other loading states
    const loadingElements = document.querySelectorAll('.loading-state, [data-loading="true"]')
    loadingElements.forEach(el => {
      el.classList.add('hidden')
      el.setAttribute('data-loading', 'false')
    })

    // Show content containers
    const contentContainers = document.querySelectorAll('[data-activity-feed-target="container"]')
    contentContainers.forEach(el => {
      el.classList.remove('hidden')
    })
  }

  showAuthenticationErrorState() {
    // Find activity feed container
    const activityFeed = document.querySelector('[data-controller*="activity-feed"]')
    if (activityFeed) {
      // Try to trigger the activity feed's own auth error handler
      const controller = this.application.getControllerForElementAndIdentifier(activityFeed, 'activity-feed')
      if (controller && controller.handleAuthenticationError) {
        controller.handleAuthenticationError()
        return
      }
    }

    // Fallback: create our own auth error state
    this.createErrorState(
      I18n.t('auth.session.authentication_required'),
      I18n.t('auth.session.session_expired_detailed'),
      'authentication',
      [
        {
          text: I18n.t('auth.session.sign_in_again'),
          href: '/users/sign_in',
          primary: true
        }
      ]
    )
  }

  showNetworkErrorState() {
    this.createErrorState(
      'Connection Problem',
      'Unable to connect to Wishare. Please check your internet connection and try again.',
      'network',
      [
        {
          text: 'Retry',
          action: 'click->web-error-handler#retryConnection',
          primary: true
        },
        {
          text: 'Refresh Page',
          action: 'click->web-error-handler#refreshPage',
          primary: false
        }
      ]
    )
  }

  showNetworkOfflineState() {
    // Show a temporary banner for offline state
    this.createBanner(
      'You\'re offline. Some features may not work until your connection is restored.',
      'warning'
    )
  }

  hideNetworkOfflineState() {
    const banner = document.getElementById('network-offline-banner')
    if (banner) {
      banner.remove()
    }
  }

  showGenericErrorState(message) {
    this.createErrorState(
      'Something went wrong',
      message || 'An unexpected error occurred. Please try refreshing the page.',
      'generic',
      [
        {
          text: 'Refresh Page',
          action: 'click->web-error-handler#refreshPage',
          primary: true
        }
      ]
    )
  }

  createErrorState(title, message, type, actions = []) {
    // Remove existing error states
    const existingError = document.getElementById('web-error-state')
    if (existingError) {
      existingError.remove()
    }

    // Find container (try activity feed first, then dashboard)
    let container = document.querySelector('[data-activity-feed-target="container"]')
    if (!container) {
      container = document.querySelector('.max-w-7xl') // Dashboard container
    }
    if (!container) {
      container = document.body
    }

    const errorDiv = document.createElement('div')
    errorDiv.id = 'web-error-state'
    errorDiv.className = 'bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-8 text-center mx-4 my-6'

    const iconColor = type === 'authentication' ? 'text-red-500' :
                     type === 'network' ? 'text-yellow-500' : 'text-gray-500'

    const icon = type === 'authentication' ?
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>' :
      type === 'network' ?
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>' :
      '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>'

    const actionsHtml = actions.map(action => {
      const buttonClass = action.primary ?
        'px-4 py-2 bg-rose-500 hover:bg-rose-600 text-white font-medium rounded-lg transition-colors' :
        'px-4 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 font-medium rounded-lg transition-colors'

      if (action.href) {
        return `<a href="${action.href}" class="inline-flex items-center gap-2 ${buttonClass}">${action.text}</a>`
      } else {
        return `<button type="button" data-action="${action.action}" class="inline-flex items-center gap-2 ${buttonClass}">${action.text}</button>`
      }
    }).join('')

    errorDiv.innerHTML = `
      <svg class="w-16 h-16 ${iconColor} mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        ${icon}
      </svg>
      <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
        ${title}
      </h3>
      <p class="text-gray-600 dark:text-gray-400 mb-6">
        ${message}
      </p>
      <div class="flex flex-col sm:flex-row gap-3 justify-center">
        ${actionsHtml}
      </div>
    `

    // Insert the error state
    if (container === document.body) {
      container.appendChild(errorDiv)
    } else {
      container.innerHTML = ''
      container.appendChild(errorDiv)
    }
  }

  createBanner(message, type = 'info') {
    const existingBanner = document.getElementById('network-offline-banner')
    if (existingBanner) {
      existingBanner.remove()
    }

    const banner = document.createElement('div')
    banner.id = 'network-offline-banner'

    const bgColor = type === 'warning' ? 'bg-yellow-500' :
                   type === 'error' ? 'bg-red-500' : 'bg-blue-500'

    banner.className = `fixed top-0 left-0 right-0 ${bgColor} text-white p-3 text-center z-50 text-sm`
    banner.innerHTML = `
      <div class="flex items-center justify-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <span>${message}</span>
      </div>
    `

    document.body.prepend(banner)
  }

  stopBackgroundProcesses() {
    // Stop any activity feed timers
    const activityFeed = document.querySelector('[data-controller*="activity-feed"]')
    if (activityFeed) {
      const controller = this.application.getControllerForElementAndIdentifier(activityFeed, 'activity-feed')
      if (controller && controller.disconnect) {
        // Don't fully disconnect, but stop timers
        if (controller.refreshInterval) {
          clearInterval(controller.refreshInterval)
        }
      }
    }

    // Stop mobile performance auth checks
    const mobilePerf = document.querySelector('[data-controller*="mobile-performance"]')
    if (mobilePerf) {
      const controller = this.application.getControllerForElementAndIdentifier(mobilePerf, 'mobile-performance')
      if (controller && controller.handleSignOut) {
        controller.handleSignOut()
      }
    }
  }

  retryFailedOperations() {
    // Retry activity feed
    const activityFeed = document.querySelector('[data-controller*="activity-feed"]')
    if (activityFeed) {
      const controller = this.application.getControllerForElementAndIdentifier(activityFeed, 'activity-feed')
      if (controller && controller.reconnect) {
        controller.reconnect()
      }
    }

    // Remove error states
    const errorState = document.getElementById('web-error-state')
    if (errorState) {
      errorState.remove()
    }
  }

  retryConnection() {
    console.log('WebErrorHandler: Retrying connection...')
    this.retryFailedOperations()
  }

  refreshPage() {
    window.location.reload()
  }
}