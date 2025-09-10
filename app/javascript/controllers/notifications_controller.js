import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static targets = ["dropdown", "badge", "list"]
  static values = { userId: Number }

  connect() {
    console.log("Notifications controller connected")
    
    // Check if targets exist
    if (this.hasDropdownTarget) {
      console.log("Dropdown target found")
    }
    
    this.subscription = consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        connected: () => {
          console.log("Connected to notifications channel")
        },
        
        disconnected: () => {
          console.log("Disconnected from notifications channel")
        },
        
        received: (data) => {
          this.handleNotification(data)
        }
      }
    )
    
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeOnClickOutside.bind(this))
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    document.removeEventListener("click", this.closeOnClickOutside.bind(this))
  }

  toggle(event) {
    console.log("Toggle clicked")
    event.preventDefault()
    event.stopPropagation()
    
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle("hidden")
      
      // Adjust positioning based on viewport space
      if (!this.dropdownTarget.classList.contains("hidden")) {
        const rect = this.dropdownTarget.getBoundingClientRect()
        const windowHeight = window.innerHeight
        const spaceBelow = windowHeight - rect.top
        
        // If dropdown extends below viewport, position it above the button
        if (spaceBelow < rect.height + 20) {
          this.dropdownTarget.classList.add("bottom-full", "mb-2")
          this.dropdownTarget.classList.remove("mt-2")
        } else {
          this.dropdownTarget.classList.remove("bottom-full", "mb-2")
          this.dropdownTarget.classList.add("mt-2")
        }
      }
      
      console.log("Dropdown toggled, hidden:", this.dropdownTarget.classList.contains("hidden"))
    } else {
      console.error("No dropdown target found")
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target) && this.hasDropdownTarget) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  handleNotification(data) {
    if (data.action === "new_notification") {
      // Update badge count
      this.updateBadge(data.count)
      
      // Add new notification to the dropdown list
      if (this.hasListTarget) {
        this.prependNotification(data.notification)
      }
      
      // Show a brief visual indicator
      this.flashBell()
    } else if (data.action === "update_count") {
      this.updateBadge(data.count)
    }
  }

  updateBadge(count) {
    if (count > 0) {
      this.badgeTarget.textContent = count
      this.badgeTarget.classList.remove("hidden")
    } else {
      this.badgeTarget.classList.add("hidden")
    }
  }

  prependNotification(notification) {
    // Add action buttons for invitation notifications
    let actionButtons = '';
    if (notification.notification_type === 'invitation_received' && notification.data && notification.data.invitation_token) {
      actionButtons = `
        <div class="flex items-center gap-1">
          <a href="/invite/${notification.data.invitation_token}" data-turbo-method="patch" 
             class="p-1 bg-green-100 hover:bg-green-200 rounded transition duration-200" 
             title="Accept">
            <svg class="w-3 h-3 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path>
            </svg>
          </a>
          <a href="/invite/${notification.data.invitation_token}?accept=false" data-turbo-method="patch" 
             class="p-1 bg-red-100 hover:bg-red-200 rounded transition duration-200" 
             title="Decline">
            <svg class="w-3 h-3 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </a>
        </div>
      `;
    }

    const notificationHtml = `
      <div class="px-4 py-3 hover:bg-gray-50 border-b border-gray-100 bg-rose-50">
        <div class="flex items-start gap-3">
          <div class="flex-shrink-0 w-2 h-2 mt-2 rounded-full bg-rose-500"></div>
          <div class="flex-1">
            <p class="text-sm font-medium text-gray-800">${notification.title}</p>
            <p class="text-xs text-gray-600 mt-1">${notification.message}</p>
            <p class="text-xs text-gray-400 mt-1">just now</p>
          </div>
          ${actionButtons}
        </div>
      </div>
    `
    
    // Remove "no notifications" message if present
    const emptyState = this.listTarget.querySelector(".text-center")
    if (emptyState) {
      emptyState.remove()
    }
    
    // Add new notification at the top
    this.listTarget.insertAdjacentHTML("afterbegin", notificationHtml)
    
    // Limit to 10 notifications in dropdown
    const notifications = this.listTarget.querySelectorAll(":scope > div")
    if (notifications.length > 10) {
      notifications[notifications.length - 1].remove()
    }
  }

  flashBell() {
    const bell = this.element.querySelector("svg")
    bell.classList.add("animate-bounce")
    setTimeout(() => {
      bell.classList.remove("animate-bounce")
    }, 1000)
  }
}