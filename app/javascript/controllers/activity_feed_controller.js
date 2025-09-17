import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["container", "loadMoreButton"]
  static values = {
    userId: Number,
    feedType: String,
    limit: { type: Number, default: 20 },
    offset: { type: Number, default: 0 }
  }

  connect() {
    this.consumer = createConsumer()
    this.initializeChannel()
    this.bindEvents()
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
        include_public: this.feedTypeValue === "all"
      },
      {
        connected: () => {
          console.log("Connected to ActivityFeedChannel")
          this.requestInitialFeed()
        },

        disconnected: () => {
          console.log("Disconnected from ActivityFeedChannel")
        },

        received: (data) => {
          this.handleReceivedData(data)
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
    this.clearFeed()

    // Tell the channel to switch feed types
    if (this.subscription) {
      this.subscription.perform('change_feed_type', { feed_type: feedType })
    }

    // Request fresh feed data
    this.requestFeedUpdate()
  }

  requestInitialFeed() {
    if (this.subscription) {
      this.subscription.perform('request_feed_update', {
        feed_type: this.feedTypeValue,
        limit: this.limitValue,
        offset: 0
      })
    }
  }

  requestFeedUpdate() {
    if (this.subscription) {
      this.subscription.perform('request_feed_update', {
        feed_type: this.feedTypeValue,
        limit: this.limitValue,
        offset: this.offsetValue
      })
    }
  }

  loadMore() {
    this.offsetValue += this.limitValue
    this.requestFeedUpdate()
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
      default:
        console.log('Unknown data type:', data.type)
    }
  }

  handleFeedUpdate(data) {
    if (this.offsetValue === 0) {
      // Fresh feed load - replace all content
      this.clearFeed()
    }

    // Add new activities to the feed
    data.activities.forEach(activity => {
      this.addActivityToFeed(activity, false) // Don't animate initial load
    })

    // Show/hide load more button based on whether there are more items
    this.toggleLoadMoreButton(data.has_more)
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
    notification.textContent = `New activity from ${activity.actor.name}`

    document.body.appendChild(notification)

    setTimeout(() => {
      notification.remove()
    }, 3000)
  }

  showFriendActivityNotification(activity) {
    // Show notification for friend activities with different styling
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-blue-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 text-sm'
    notification.textContent = `${activity.actor.name} ${this.getActivityDescription(activity)}`

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
}