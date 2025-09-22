import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["welcomeMessage", "timeOfDay", "userStats"]
  static values = {
    userName: String,
    lastVisit: String,
    refreshInterval: { type: Number, default: 300000 } // 5 minutes
  }

  connect() {
    this.updateTimeOfDay()
    this.startPeriodicRefresh()
    this.observeVisibilityChange()
  }

  disconnect() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
    if (this.visibilityChangeHandler) {
      document.removeEventListener("visibilitychange", this.visibilityChangeHandler)
    }
  }

  updateTimeOfDay() {
    if (!this.hasTimeOfDayTarget) return

    const hour = new Date().getHours()
    let greeting

    if (hour >= 5 && hour < 12) {
      greeting = this.getLocalizedGreeting("morning")
    } else if (hour >= 12 && hour < 18) {
      greeting = this.getLocalizedGreeting("afternoon")
    } else {
      greeting = this.getLocalizedGreeting("evening")
    }

    this.timeOfDayTarget.textContent = greeting
  }

  getLocalizedGreeting(timeOfDay) {
    // This would typically come from the server or be set as data attributes
    const greetings = {
      morning: "Good morning! Here's what's happening today",
      afternoon: "Good afternoon! Here's what's happening today",
      evening: "Good evening! Here's what's happening today"
    }

    return greetings[timeOfDay] || greetings.morning
  }

  startPeriodicRefresh() {
    // Only refresh if the page is visible to save resources
    this.refreshTimer = setInterval(() => {
      if (!document.hidden) {
        this.refreshDashboard()
      }
    }, this.refreshIntervalValue)
  }

  observeVisibilityChange() {
    this.visibilityChangeHandler = () => {
      if (!document.hidden) {
        // Page became visible, update time-sensitive content
        this.updateTimeOfDay()
        this.refreshNotifications()
      }
    }
    document.addEventListener("visibilitychange", this.visibilityChangeHandler)
  }

  refreshDashboard() {
    // Use Turbo Stream to refresh specific sections without full page reload
    this.refreshNotifications()
    this.refreshPendingInvitations()
    this.updateTimeBasedContent()
  }

  refreshNotifications() {
    // Fetch and update notifications count
    fetch('/api/v1/notifications/unread_count', {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.updateNotificationBadge(data.count)
    })
    .catch(error => {
      console.warn('Failed to refresh notifications:', error)
    })
  }

  refreshPendingInvitations() {
    // TODO: Implement server-side endpoint for dynamic invitation updates
    // For now, pending invitations are loaded on initial page load
    console.debug('Pending invitations refresh - not implemented yet')
  }

  updateTimeBasedContent() {
    // Update time-sensitive elements like "5 minutes ago", "2 hours ago", etc.
    const timeElements = document.querySelectorAll('[data-time-ago]')
    timeElements.forEach(element => {
      const timestamp = element.dataset.timeAgo
      if (timestamp) {
        element.textContent = this.formatTimeAgo(new Date(timestamp))
      }
    })
  }

  formatTimeAgo(timestamp) {
    const now = new Date()
    const diffInMs = now - timestamp
    const diffInMinutes = Math.floor(diffInMs / (1000 * 60))
    const diffInHours = Math.floor(diffInMs / (1000 * 60 * 60))
    const diffInDays = Math.floor(diffInMs / (1000 * 60 * 60 * 24))

    if (diffInMinutes < 5) {
      return "Just now"
    } else if (diffInMinutes < 60) {
      return `${diffInMinutes}m ago`
    } else if (diffInHours < 24) {
      return `${diffInHours}h ago`
    } else if (diffInDays < 7) {
      return `${diffInDays}d ago`
    } else {
      return timestamp.toLocaleDateString()
    }
  }

  updateNotificationBadge(count) {
    const badge = document.querySelector('[data-notification-count]')
    if (badge) {
      badge.textContent = count
      badge.style.display = count > 0 ? 'inline-flex' : 'none'
    }
  }

  // Handle real-time updates via ActionCable
  handleRealtimeUpdate(data) {
    switch (data.type) {
      case 'notification':
        this.addNewNotification(data.notification)
        break
      case 'invitation':
        this.addNewInvitation(data.invitation)
        break
      case 'friend_activity':
        this.updateFriendActivity(data.activity)
        break
    }
  }

  addNewNotification(notification) {
    const notificationsContainer = document.querySelector('[data-section="notifications"] .space-y-3')
    if (notificationsContainer) {
      // Add notification to the top of the list
      const notificationHtml = this.buildNotificationHtml(notification)
      notificationsContainer.insertAdjacentHTML('afterbegin', notificationHtml)

      // Remove oldest notification if we have more than 5
      const notifications = notificationsContainer.children
      if (notifications.length > 5) {
        notifications[notifications.length - 1].remove()
      }

      // Update notification count
      this.refreshNotifications()
    }
  }

  addNewInvitation(invitation) {
    const invitationsContainer = document.querySelector('[data-section="pending-invitations"] .space-y-3')
    if (invitationsContainer) {
      const invitationHtml = this.buildInvitationHtml(invitation)
      invitationsContainer.insertAdjacentHTML('afterbegin', invitationHtml)
    }
  }

  updateFriendActivity(activity) {
    // Update friend-related sections when friends add items, create wishlists, etc.
    this.refreshRecentItems()
  }

  refreshRecentItems() {
    // TODO: Implement server-side endpoint for dynamic recent items updates
    // For now, recent items are loaded on initial page load
    console.debug('Recent items refresh - not implemented yet')
  }

  buildNotificationHtml(notification) {
    return `
      <div class="flex items-start space-x-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
        <div class="flex-shrink-0 w-2 h-2 bg-pink-500 rounded-full mt-2"></div>
        <div class="flex-1">
          <p class="text-sm text-gray-900 dark:text-white">
            ${notification.message}
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Just now
          </p>
        </div>
      </div>
    `
  }

  buildInvitationHtml(invitation) {
    return `
      <div class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
        <div class="flex items-center space-x-3">
          <div class="w-10 h-10 rounded-full bg-pink-500 flex items-center justify-center text-white font-semibold">
            ${invitation.sender_name.charAt(0).toUpperCase()}
          </div>
          <div>
            <p class="font-medium text-gray-900 dark:text-white text-sm">
              ${invitation.sender_name}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-400">
              Just now
            </p>
          </div>
        </div>
        <div class="flex space-x-2">
          <button class="btn-primary px-3 py-1 text-xs rounded-md">
            Accept
          </button>
          <button class="btn-secondary px-3 py-1 text-xs rounded-md">
            Decline
          </button>
        </div>
      </div>
    `
  }

  // Analytics tracking
  trackDashboardInteraction(action, section) {
    // Send analytics event
    if (window.gtag) {
      window.gtag('event', action, {
        event_category: 'Dashboard',
        event_label: section
      })
    }
  }

  // Handle click events on dashboard elements
  handleSectionClick(event) {
    const section = event.currentTarget.dataset.section
    this.trackDashboardInteraction('section_view', section)
  }

  handleCardClick(event) {
    const cardType = event.currentTarget.dataset.cardType
    this.trackDashboardInteraction('card_click', cardType)
  }
}