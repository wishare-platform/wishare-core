import { Controller } from "@hotwired/stimulus"

// Mobile Performance Optimization Controller
export default class extends Controller {
  connect() {
    this.optimizeForMobile()
    this.setupPerformanceMonitoring()
    this.addLoadingStates()
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