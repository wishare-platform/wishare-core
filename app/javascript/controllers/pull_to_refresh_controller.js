import { Controller } from "@hotwired/stimulus"

// Pull-to-refresh Controller for Mobile Dashboard
export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.initializePullToRefresh()
  }

  initializePullToRefresh() {
    let startY = 0
    let currentY = 0
    let pullDistance = 0
    const pullThreshold = 80
    let isPulling = false
    let refreshIndicator = null

    // Create refresh indicator
    this.createRefreshIndicator()

    this.element.addEventListener('touchstart', (e) => {
      if (window.scrollY === 0) {
        startY = e.touches[0].clientY
        isPulling = true
      }
    }, { passive: true })

    this.element.addEventListener('touchmove', (e) => {
      if (!isPulling) return

      currentY = e.touches[0].clientY
      pullDistance = Math.max(0, currentY - startY)

      if (pullDistance > 0) {
        this.updatePullIndicator(pullDistance, pullThreshold)

        // Add resistance effect
        const resistance = Math.min(pullDistance * 0.4, pullThreshold * 0.4)
        this.element.style.transform = `translateY(${resistance}px)`

        // Prevent default scrolling when pulling
        if (pullDistance > 10) {
          e.preventDefault()
        }
      }
    }, { passive: false })

    this.element.addEventListener('touchend', () => {
      if (isPulling) {
        if (pullDistance > pullThreshold) {
          this.triggerRefresh()
        } else {
          this.resetPullState()
        }
      }

      isPulling = false
      pullDistance = 0
    }, { passive: true })
  }

  createRefreshIndicator() {
    const indicator = document.createElement('div')
    indicator.id = 'pull-refresh-indicator'
    indicator.className = 'fixed top-0 left-1/2 transform -translate-x-1/2 -translate-y-full z-50 flex items-center gap-2 px-4 py-2 bg-white dark:bg-gray-800 rounded-b-lg shadow-lg border border-gray-200 dark:border-gray-700 transition-transform duration-300'
    indicator.innerHTML = `
      <svg class="w-4 h-4 text-rose-500 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
      </svg>
      <span class="text-sm text-gray-700 dark:text-gray-300">Pull to refresh</span>
    `
    document.body.appendChild(indicator)
    this.refreshIndicator = indicator
  }

  updatePullIndicator(distance, threshold) {
    if (!this.refreshIndicator) return

    const progress = Math.min(distance / threshold, 1)
    const translateY = Math.min(progress * 60 - 60, 0)

    this.refreshIndicator.style.transform = `translate(-50%, ${translateY}px)`

    // Update indicator text and icon based on progress
    const icon = this.refreshIndicator.querySelector('svg')
    const text = this.refreshIndicator.querySelector('span')

    if (progress >= 1) {
      text.textContent = 'Release to refresh'
      icon.classList.add('text-green-500')
      icon.classList.remove('text-rose-500')
      this.refreshIndicator.classList.add('bg-green-50', 'dark:bg-green-900/20')
      this.refreshIndicator.classList.remove('bg-white', 'dark:bg-gray-800')
    } else {
      text.textContent = 'Pull to refresh'
      icon.classList.add('text-rose-500')
      icon.classList.remove('text-green-500')
      this.refreshIndicator.classList.add('bg-white', 'dark:bg-gray-800')
      this.refreshIndicator.classList.remove('bg-green-50', 'dark:bg-green-900/20')
    }
  }

  triggerRefresh() {
    // Show loading state
    if (this.refreshIndicator) {
      const text = this.refreshIndicator.querySelector('span')
      text.textContent = 'Refreshing...'

      this.refreshIndicator.style.transform = 'translate(-50%, 0)'
    }

    // Add haptic feedback
    if ('vibrate' in navigator) {
      navigator.vibrate(50)
    }

    // Use Turbo to refresh content instead of full reload
    this.refreshContent()
  }

  async refreshContent() {
    try {
      // Fetch fresh content using Turbo
      const response = await fetch(window.location.pathname + '?refresh=true', {
        headers: {
          'Accept': 'text/html',
          'Turbo-Frame': 'refresh'
        }
      })

      if (response.ok) {
        // Use Turbo to update the page content
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')

        // Find and update the main content area
        const newContent = doc.querySelector('[data-controller="pull-to-refresh"]')
        const currentContent = this.element

        if (newContent && currentContent) {
          // Replace the content while preserving the controller
          currentContent.innerHTML = newContent.innerHTML

          // Dispatch a custom event to notify other controllers of the refresh
          this.element.dispatchEvent(new CustomEvent('content-refreshed', {
            bubbles: true,
            detail: { timestamp: Date.now() }
          }))
        }

        // Success feedback
        this.showRefreshSuccess()
      } else {
        this.showRefreshError()
      }
    } catch (error) {
      console.error('Pull to refresh failed:', error)
      this.showRefreshError()
    }

    // Always reset the UI after refresh attempt
    setTimeout(() => {
      this.resetPullState()
    }, 500)
  }

  showRefreshSuccess() {
    if (this.refreshIndicator) {
      const text = this.refreshIndicator.querySelector('span')
      const icon = this.refreshIndicator.querySelector('svg')

      text.textContent = 'Updated!'
      icon.classList.remove('animate-spin', 'text-rose-500')
      icon.classList.add('text-green-500')

      this.refreshIndicator.classList.add('bg-green-50', 'dark:bg-green-900/20')
      this.refreshIndicator.classList.remove('bg-white', 'dark:bg-gray-800')
    }
  }

  showRefreshError() {
    if (this.refreshIndicator) {
      const text = this.refreshIndicator.querySelector('span')
      text.textContent = 'Update failed'

      this.refreshIndicator.classList.add('bg-red-50', 'dark:bg-red-900/20')
      this.refreshIndicator.classList.remove('bg-white', 'dark:bg-gray-800')
    }
  }

  resetPullState() {
    // Reset transforms
    this.element.style.transform = ''

    if (this.refreshIndicator) {
      this.refreshIndicator.style.transform = 'translate(-50%, -100%)'
    }
  }

  disconnect() {
    // Clean up refresh indicator
    if (this.refreshIndicator) {
      this.refreshIndicator.remove()
    }
  }
}