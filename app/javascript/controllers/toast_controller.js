import { Controller } from "@hotwired/stimulus"

// Toast Notification System for Wishare
// Usage: data-controller="toast"
//        data-action="click->toast#show"
//        data-toast-message-value="Success!"
//        data-toast-type-value="success"

export default class extends Controller {
  static values = {
    message: String,
    type: String,    // success, error, warning, info
    duration: { type: Number, default: 3000 },
    icon: String
  }

  connect() {
    // Create toast container if it doesn't exist
    if (!document.querySelector('.toast-container')) {
      const container = document.createElement('div')
      container.className = 'toast-container'
      document.body.appendChild(container)
    }
  }

  // Show toast with message
  show(event) {
    const message = this.hasMessageValue ? this.messageValue : event.params?.message || "Notification"
    const type = this.hasTypeValue ? this.typeValue : event.params?.type || "info"
    const icon = this.hasIconValue ? this.iconValue : event.params?.icon || this.getDefaultIcon(type)
    const duration = this.hasDurationValue ? this.durationValue : event.params?.duration || 3000

    this.createToast(message, type, icon, duration)
  }

  // Create and display toast
  createToast(message, type, icon, duration) {
    const container = document.querySelector('.toast-container')
    const toast = document.createElement('div')

    // Set toast classes
    toast.className = `toast toast-${type}`

    // Set toast content
    toast.innerHTML = `
      <span class="toast-icon">${icon}</span>
      <span class="toast-message">${message}</span>
    `

    // Append to container
    container.appendChild(toast)

    // Trigger animation
    setTimeout(() => {
      toast.classList.add('show')
    }, 10)

    // Auto-hide after duration
    setTimeout(() => {
      toast.classList.remove('show')

      // Remove from DOM after animation
      setTimeout(() => {
        toast.remove()
      }, 300)
    }, duration)
  }

  // Get default icon for toast type
  getDefaultIcon(type) {
    const icons = {
      success: '✅',
      error: '❌',
      warning: '⚠️',
      info: 'ℹ️'
    }
    return icons[type] || '✨'
  }

  // Static method to show toast from anywhere
  static showToast(message, type = 'info', icon = null, duration = 3000) {
    const container = document.querySelector('.toast-container') || (() => {
      const div = document.createElement('div')
      div.className = 'toast-container'
      document.body.appendChild(div)
      return div
    })()

    const toast = document.createElement('div')
    toast.className = `toast toast-${type}`

    const finalIcon = icon || {
      success: '✅',
      error: '❌',
      warning: '⚠️',
      info: 'ℹ️'
    }[type] || '✨'

    toast.innerHTML = `
      <span class="toast-icon">${finalIcon}</span>
      <span class="toast-message">${message}</span>
    `

    container.appendChild(toast)

    setTimeout(() => toast.classList.add('show'), 10)

    setTimeout(() => {
      toast.classList.remove('show')
      setTimeout(() => toast.remove(), 300)
    }, duration)
  }
}

// Make available globally for Rails views
window.showToast = (message, type = 'info', icon = null, duration = 3000) => {
  import('./toast_controller.js').then(module => {
    module.default.showToast(message, type, icon, duration)
  })
}
