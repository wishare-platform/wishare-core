import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["container", "loadMoreButton", "emptyState", "loadingState", "activityCount"]
  static values = {
    userId: Number,
    feedType: String,
    locale: String,
    limit: { type: Number, default: 30 },
    offset: { type: Number, default: 0 },
    noActivities: String,
    oneActivity: String,
    multipleActivities: String,
    newActivityNotification: String,
    friendNotificationPrefix: String
  }

  connect() {
    this.authenticationError = false
    this.connectionTimeout = null
    this.httpFallbackAttempted = false
    this.nextCursor = null
    this.hasMore = true
    this.isLoading = false
    this.consumer = createConsumer()
    this.initializeChannel()
    this.bindEvents()
    this.setupExternalElements()
    this.startConnectionTimeout()

    // For web users, attempt HTTP fallback immediately if WebSocket fails
    if (!this.isMobileApp()) {
      setTimeout(() => {
        if (!this.subscription || this.subscription.state !== 'connected') {
          console.log('WebSocket not connected after 3s, trying HTTP fallback')
          this.loadFeedViaHTTP()
        }
      }, 3000)
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  initializeChannel() {
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: "ActivityFeedChannel",
        include_public: this.feedTypeValue === "all",
        locale: this.localeValue
      },
      {
        connected: () => {
          console.log('ActivityFeed WebSocket connected')
          this.clearConnectionTimeout()
          this.authenticationError = false
          this.httpFallbackAttempted = false
          this.requestInitialFeed()
        },

        disconnected: () => {
          // Connection lost - check if it's an authentication issue
          this.handleConnectionLost()
        },

        received: (data) => {
          this.clearConnectionTimeout()
          this.handleReceivedData(data)
        },

        rejected: () => {
          console.error("ActivityFeedChannel connection rejected - likely authentication issue")
          // Try HTTP fallback before showing auth error
          if (!this.httpFallbackAttempted) {
            console.log('WebSocket rejected, trying HTTP fallback')
            this.loadFeedViaHTTP().catch(() => {
              this.handleAuthenticationError()
            })
          } else {
            this.handleAuthenticationError()
          }
        }
      }
    )
  }

  bindEvents() {
    // Listen for feed type changes from tabs
    document.addEventListener('activity-feed:change-type', (event) => {
      this.changeFeedType(event.detail.feedType)
    })

    // Auto-refresh every 30 seconds for active feeds
    this.refreshInterval = setInterval(() => {
      if (document.visibilityState === 'visible') {
        this.requestFeedUpdate()
      }
    }, 30000)
  }

  changeFeedType(feedType) {
    this.feedTypeValue = feedType
    this.offsetValue = 0
    this.nextCursor = null
    this.hasMore = true
    this.clearFeed()

    // Tell the channel to switch feed types
    if (this.subscription) {
      this.subscription.perform('change_feed_type', { feed_type: feedType })
    }

    // Request fresh feed data
    this.requestFeedUpdate()
  }

  requestInitialFeed() {
    if (this.subscription && this.subscription.state === 'connected') {
      this.subscription.perform('request_feed_update', {
        feed_type: this.feedTypeValue,
        limit: this.limitValue,
        cursor: null
      })
    } else {
      // Immediate fallback to HTTP API if WebSocket is not available
      console.log('WebSocket not connected, using HTTP fallback')
      this.loadFeedViaHTTP()
    }
  }

  requestFeedUpdate(cursor = null) {
    if (this.subscription) {
      this.subscription.perform('request_feed_update', {
        feed_type: this.feedTypeValue,
        limit: this.limitValue,
        cursor: cursor || this.nextCursor
      })
    }
  }

  refreshFeed() {
    this.offsetValue = 0
    this.nextCursor = null
    this.hasMore = true
    this.showLoadingState()
    this.requestFeedUpdate(null)
  }

  loadMore() {
    if (this.isLoading || !this.hasMore) return

    this.isLoading = true
    this.updateLoadMoreButton()

    if (this.subscription) {
      this.subscription.perform('load_more_activities', {
        feed_type: this.feedTypeValue,
        limit: this.limitValue,
        cursor: this.nextCursor
      })
    } else {
      // HTTP fallback for load more
      this.loadFeedViaHTTP(true)
    }
  }

  handleReceivedData(data) {
    switch (data.type) {
      case 'feed_update':
        this.handleFeedUpdate(data)
        break
      case 'new_activity':
        this.handleNewActivity(data)
        break
      case 'friend_activity':
        this.handleFriendActivity(data)
        break
      case 'error':
        this.handleErrorResponse(data)
        break
      default:
        console.log('Unknown data type:', data.type)
    }
  }

  handleFeedUpdate(data) {
    // Hide loading state and show container
    this.hideLoadingState()
    this.isLoading = false

    // Handle cursor-based pagination
    if (data.next_cursor) {
      this.nextCursor = data.next_cursor
    }
    this.hasMore = data.has_more || false

    if (!data.is_load_more) {
      // Fresh feed load - replace all content
      this.clearFeed()
    }

    // Check if we have activities to show
    if (data.activities && data.activities.length > 0) {
      // Hide empty state if it was showing
      this.hideEmptyState()

      // Add new activities to the feed
      data.activities.forEach(activity => {
        this.addActivityToFeed(activity, false) // Don't animate initial load
      })

      // Update activity count
      this.updateActivityCount(data.activities.length)
    } else if (!data.is_load_more) {
      // Show empty state only on initial load with no activities
      this.showEmptyState()
      this.updateActivityCount(0)
    }

    // Update load more button visibility
    this.updateLoadMoreButton()
  }

  handleNewActivity(data) {
    // Only add if this is a fresh activity (not from pagination)
    if (this.offsetValue === 0) {
      this.addActivityToFeed(data.activity, true) // Animate new activities
      this.showNewActivityNotification(data.activity)
    }
  }

  handleFriendActivity(data) {
    // Only show friend activities if we're on friends feed or for_you feed
    if (['friends', 'for_you'].includes(this.feedTypeValue)) {
      this.addActivityToFeed(data.activity, true)
      this.showFriendActivityNotification(data.activity)
    }
  }

  addActivityToFeed(activity, animate = false) {
    // Check if activity already exists to prevent duplicates
    if (this.containerTarget.querySelector(`[data-activity-id="${activity.id}"]`)) {
      return
    }

    const activityElement = this.createActivityElement(activity)

    if (animate) {
      activityElement.classList.add('opacity-0', 'transform', 'scale-95')
      this.containerTarget.prepend(activityElement)

      // Animate in
      setTimeout(() => {
        activityElement.classList.remove('opacity-0', 'scale-95')
        activityElement.classList.add('transition-all', 'duration-300')
      }, 10)
    } else {
      this.containerTarget.appendChild(activityElement)
    }
  }

  createActivityElement(activity) {
    const template = document.createElement('div')
    template.className = 'bg-white dark:bg-gray-800 rounded-lg shadow p-4 mb-4 border border-gray-200 dark:border-gray-700'
    template.setAttribute('data-activity-id', activity.id)

    template.innerHTML = `
      <div class="flex items-start space-x-3">
        <img src="${activity.actor.avatar_url || '/assets/default-avatar.png'}"
             alt="${activity.actor.name}"
             class="w-10 h-10 rounded-full">
        <div class="flex-1 min-w-0">
          <div class="text-sm text-gray-900 dark:text-gray-100">
            <span class="font-medium">${this.escapeHtml(activity.actor.name)}</span>
            ${this.getActivityDescription(activity)}
          </div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            ${activity.time_ago}
          </div>
          ${this.getTargetPreview(activity.target)}
        </div>
      </div>
    `

    return template
  }

  getActivityDescription(activity) {
    // Use the translated description from the backend if available
    if (activity.action_description) {
      return activity.action_description
    }

    // Fallback to hardcoded values (should not be reached if backend is sending action_description)
    const actions = {
      'wishlist_created': 'created a new wishlist',
      'item_added': 'added an item to their wishlist',
      'item_purchased': 'purchased an item',
      'wishlist_liked': 'liked a wishlist',
      'wishlist_commented': 'commented on a wishlist',
      'friend_connected': 'connected with a friend',
      'profile_updated': 'updated their profile',
      'wishlist_shared': 'shared a wishlist'
    }

    return actions[activity.action_type] || 'performed an action'
  }

  getTargetPreview(target) {
    if (!target) return ''

    switch (target.type) {
      case 'Wishlist':
        return `
          <div class="mt-2 p-2 bg-gray-50 dark:bg-gray-700 rounded border">
            <a href="${target.url}" class="text-sm font-medium text-rose-600 dark:text-rose-400 hover:underline">
              ${this.escapeHtml(target.name)}
            </a>
            ${target.event_type ? `<div class="text-xs text-gray-500">${target.event_type}</div>` : ''}
          </div>
        `
      case 'WishlistItem':
        return `
          <div class="mt-2 p-2 bg-gray-50 dark:bg-gray-700 rounded border">
            <a href="${target.url}" class="text-sm font-medium text-rose-600 dark:text-rose-400 hover:underline">
              ${this.escapeHtml(target.name)}
            </a>
            <div class="text-xs text-gray-500">
              ${target.price ? `${target.currency} ${target.price}` : ''}
              ${target.wishlist_name ? `• ${target.wishlist_name}` : ''}
            </div>
          </div>
        `
      default:
        return ''
    }
  }

  clearFeed() {
    this.containerTarget.innerHTML = ''
  }

  toggleLoadMoreButton(hasMore) {
    if (this.hasLoadMoreButtonTarget) {
      this.loadMoreButtonTarget.style.display = hasMore ? 'block' : 'none'
    }
  }

  showNewActivityNotification(activity) {
    // Show a subtle notification for new activities
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-rose-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 text-sm'
    const message = (this.newActivityNotificationValue || 'New activity from __NAME__').replace('__NAME__', activity.actor.name)
    notification.textContent = message

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  showFriendActivityNotification(activity) {
    // Show notification for friend activities with different styling
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-blue-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 text-sm'
    const prefix = (this.friendNotificationPrefixValue || '__NAME__').replace('__NAME__', activity.actor.name)
    notification.textContent = `${prefix} ${this.getActivityDescription(activity)}`

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  showEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.remove('hidden')
    }
  }

  hideEmptyState() {
    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.classList.add('hidden')
    }
  }

  showLoadingState() {
    if (this.hasLoadingStateTarget) {
      this.loadingStateTarget.classList.remove('hidden')
    }
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add('hidden')
    }
    this.hideEmptyState()
  }

  hideLoadingState() {
    if (this.hasLoadingStateTarget) {
      this.loadingStateTarget.classList.add('hidden')
    }
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove('hidden')
    }
  }

  updateActivityCount(count) {
    let text
    if (count === 0) {
      text = this.noActivitiesValue || 'No activities yet'
    } else if (count === 1) {
      text = this.oneActivityValue || '1 activity'
    } else {
      text = (this.multipleActivitiesValue || `${count} activities`).replace('__COUNT__', count)
    }

    // Update Stimulus target if available
    if (this.hasActivityCountTarget) {
      this.activityCountTarget.textContent = text
    }

    // Update external element
    const externalCounter = document.getElementById('activity-count-display')
    if (externalCounter) {
      externalCounter.textContent = text
    }
  }

  setupExternalElements() {
    // Setup refresh button
    const refreshButton = document.getElementById('refresh-feed-button')
    if (refreshButton) {
      refreshButton.addEventListener('click', () => {
        this.refreshFeed()
      })
    }
  }

  // Connection timeout management
  startConnectionTimeout() {
    this.connectionTimeout = setTimeout(() => {
      if (!this.subscription || this.subscription.state !== 'connected') {
        console.log('Connection timeout, attempting HTTP fallback')
        if (!this.httpFallbackAttempted) {
          this.loadFeedViaHTTP().catch(() => {
            this.handleConnectionTimeout()
          })
        } else {
          this.handleConnectionTimeout()
        }
      }
    }, 5000) // Reduced to 5 second timeout for faster fallback
  }

  clearConnectionTimeout() {
    if (this.connectionTimeout) {
      clearTimeout(this.connectionTimeout)
      this.connectionTimeout = null
    }
  }

  // Error handling methods
  handleConnectionTimeout() {
    console.warn('ActivityFeed connection timeout - possible authentication issue')
    this.showAuthenticationError('Connection timeout. Please check your internet connection or try logging in again.')
  }

  handleConnectionLost() {
    console.warn('ActivityFeed connection lost')
    // Try to reconnect after a delay if not an auth error
    if (!this.authenticationError) {
      setTimeout(() => {
        this.reconnect()
      }, 3000)
    }
  }

  handleAuthenticationError() {
    this.authenticationError = true
    this.showAuthenticationError('Authentication required. Please log in to view your activity feed.')
  }

  handleErrorResponse(data) {
    console.error('Error from ActivityFeed:', data.message)
    if (data.message && data.message.includes('authentication')) {
      this.handleAuthenticationError()
    } else {
      this.showGenericError(data.message || 'An error occurred while loading your feed.')
    }
  }

  showAuthenticationError(message) {
    this.hideLoadingState()
    this.hideEmptyState()
    this.showErrorState(message, 'authentication')
  }

  showGenericError(message) {
    this.hideLoadingState()
    this.showErrorState(message, 'generic')
  }

  showErrorState(message, type = 'generic') {
    // Create or update error state
    let errorState = this.element.querySelector('[data-activity-feed-target="errorState"]')
    if (!errorState) {
      errorState = document.createElement('div')
      errorState.setAttribute('data-activity-feed-target', 'errorState')
      this.element.appendChild(errorState)
    }

    const isAuthError = type === 'authentication'
    const iconColor = isAuthError ? 'text-red-500' : 'text-yellow-500'
    const bgColor = isAuthError ? 'border-red-200 dark:border-red-700' : 'border-yellow-200 dark:border-yellow-700'

    errorState.className = `bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-sm border ${bgColor} p-8 text-center`
    errorState.innerHTML = `
      <svg class="w-16 h-16 ${iconColor} mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        ${isAuthError ?
          '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path>' :
          '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>'
        }
      </svg>
      <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
        ${isAuthError ? 'Authentication Required' : 'Connection Error'}
      </h3>
      <p class="text-gray-600 dark:text-gray-400 mb-6">
        ${message}
      </p>
      <div class="flex flex-col sm:flex-row gap-3 justify-center">
        ${isAuthError ?
          `<a href="${window.location.origin}/users/sign_in"
             class="inline-flex items-center gap-2 px-4 py-2 bg-rose-500 hover:bg-rose-600 text-white font-medium rounded-lg transition-colors">
             <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"></path>
             </svg>
             Sign In
           </a>` :
          `<button type="button" onclick="location.reload()"
             class="inline-flex items-center gap-2 px-4 py-2 bg-rose-500 hover:bg-rose-600 text-white font-medium rounded-lg transition-colors">
             <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
               <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
             </svg>
             Retry
           </button>`
        }
        <button type="button"
                class="inline-flex items-center gap-2 px-4 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 font-medium rounded-lg transition-colors"
                data-action="click->activity-feed#reconnect">
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.111 16.404a5.5 5.5 0 017.778 0M12 20h.01m-7.08-7.071c3.904-3.905 10.236-3.905 14.141 0M1.394 9.393c5.857-5.857 15.355-5.857 21.213 0"></path>
          </svg>
          Reconnect
        </button>
      </div>
    `

    errorState.classList.remove('hidden')
  }

  hideErrorState() {
    const errorState = this.element.querySelector('[data-activity-feed-target="errorState"]')
    if (errorState) {
      errorState.classList.add('hidden')
    }
  }

  reconnect() {
    console.log('Attempting to reconnect ActivityFeed...')
    this.hideErrorState()
    this.showLoadingState()

    // Disconnect current subscription
    if (this.subscription) {
      this.subscription.unsubscribe()
    }

    // Reset state
    this.authenticationError = false

    // Try HTTP fallback first, then reinitialize WebSocket
    this.loadFeedViaHTTP().then(() => {
      // If HTTP works, try to reinitialize WebSocket in background
      setTimeout(() => {
        this.initializeChannel()
        this.startConnectionTimeout()
      }, 1000)
    }).catch(() => {
      // If HTTP also fails, try WebSocket
      this.initializeChannel()
      this.startConnectionTimeout()
    })
  }

  // HTTP fallback method
  async loadFeedViaHTTP() {
    try {
      console.log('Loading feed via HTTP fallback...')
      this.httpFallbackAttempted = true

      const response = await fetch('/dashboard/api_data', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        credentials: 'same-origin'
      })

      if (response.status === 401 || response.status === 403) {
        // Authentication error
        this.handleAuthenticationError()
        return Promise.reject(new Error('Authentication required'))
      }

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()

      if (data.error) {
        throw new Error(data.error)
      }

      // Convert HTTP response to feed format
      const feedData = {
        type: 'feed_update',
        activities: data.recent_activities || [],
        has_more: false // HTTP fallback shows limited data
      }

      this.handleFeedUpdate(feedData)

      // Show fallback notice
      this.showFallbackNotice()

      return Promise.resolve()

    } catch (error) {
      console.error('HTTP fallback failed:', error)
      if (error.message.includes('Authentication') || error.message.includes('401')) {
        this.handleAuthenticationError()
      } else {
        this.showGenericError(`Unable to load feed: ${error.message}`)
      }
      return Promise.reject(error)
    }
  }

  showFallbackNotice() {
    // Show a notice that we're using HTTP fallback
    const notice = document.createElement('div')
    notice.className = 'bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-lg p-3 mb-4 text-sm'
    notice.innerHTML = `
      <div class="flex items-center gap-2">
        <svg class="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <span class="text-blue-700 dark:text-blue-300">Using simplified feed mode. Real-time updates may be limited.</span>
      </div>
    `

    this.containerTarget.prepend(notice)

    // Remove notice after 5 seconds
    setTimeout(() => {
      notice.remove()
    }, 5000)
  }

  updateLoadMoreButton() {
    if (!this.hasLoadMoreButtonTarget) return

    if (this.isLoading) {
      this.loadMoreButtonTarget.innerHTML = `
        <div class="flex items-center justify-center gap-2 py-3">
          <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-rose-500"></div>
          <span class="text-gray-600 dark:text-gray-400">Loading more...</span>
        </div>
      `
      this.loadMoreButtonTarget.disabled = true
    } else if (this.hasMore) {
      this.loadMoreButtonTarget.innerHTML = `
        <div class="flex items-center justify-center gap-2 py-3">
          <span class="text-rose-600 dark:text-rose-400 font-medium">Load More Activities</span>
          <svg class="w-4 h-4 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path>
          </svg>
        </div>
      `
      this.loadMoreButtonTarget.disabled = false
      this.loadMoreButtonTarget.classList.remove('hidden')
    } else {
      this.loadMoreButtonTarget.classList.add('hidden')
    }
  }

  // Helper method to detect mobile app
  isMobileApp() {
    return navigator.userAgent.includes('Hotwire Native') ||
           window.webkit?.messageHandlers?.authBridge ||
           document.documentElement.classList.contains('mobile-app') ||
           window.location.search.includes('mobile=true')
  }
}