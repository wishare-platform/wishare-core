import { Controller } from "@hotwired/stimulus"
import { useTimeout } from "stimulus-use"

// Loading States Controller - Smooth loading experiences for Wishare
export default class extends Controller {
  static targets = [
    "skeleton", "content", "loadingSpinner", "loadingText",
    "progressBar", "shimmer", "pulseItem", "fadeContainer"
  ]
  static values = {
    duration: { type: Number, default: 300 },
    skeletonCount: { type: Number, default: 3 },
    progressDuration: { type: Number, default: 2000 },
    loadingMessages: { type: Array, default: ["Loading...", "Getting your wishlists...", "Almost ready!"] }
  }

  connect() {
    useTimeout(this)
    this.currentMessageIndex = 0
    this.setupInitialState()
  }

  setupInitialState() {
    // Hide content initially
    this.contentTargets.forEach(target => {
      target.style.opacity = '0'
      target.style.transform = 'translateY(10px)'
    })

    // Show skeleton loading
    this.showSkeletonLoading()
  }

  // Show skeleton loading state
  showSkeletonLoading() {
    this.skeletonTargets.forEach((skeleton, index) => {
      skeleton.classList.remove('hidden')
      skeleton.style.animationDelay = `${index * 100}ms`
    })

    // Generate dynamic skeleton items if needed
    if (this.skeletonCount > this.skeletonTargets.length) {
      this.generateSkeletonItems()
    }

    // Start shimmer animation
    this.startShimmerEffect()
  }

  // Generate skeleton items dynamically
  generateSkeletonItems() {
    const container = this.element.querySelector('[data-skeleton-container]')
    if (!container) return

    const additionalCount = this.skeletonCountValue - this.skeletonTargets.length

    for (let i = 0; i < additionalCount; i++) {
      const skeletonItem = this.createSkeletonItem(i)
      container.appendChild(skeletonItem)
    }
  }

  createSkeletonItem(index) {
    const item = document.createElement('div')
    item.className = 'skeleton-item animate-pulse bg-gray-200 dark:bg-gray-700 rounded-lg mb-4'
    item.style.animationDelay = `${(this.skeletonTargets.length + index) * 100}ms`

    item.innerHTML = `
      <div class="p-4 space-y-3">
        <div class="h-4 bg-gray-300 dark:bg-gray-600 rounded w-3/4"></div>
        <div class="space-y-2">
          <div class="h-3 bg-gray-300 dark:bg-gray-600 rounded"></div>
          <div class="h-3 bg-gray-300 dark:bg-gray-600 rounded w-5/6"></div>
        </div>
        <div class="flex space-x-2">
          <div class="h-8 bg-gray-300 dark:bg-gray-600 rounded w-20"></div>
          <div class="h-8 bg-gray-300 dark:bg-gray-600 rounded w-16"></div>
        </div>
      </div>
    `

    return item
  }

  // Start shimmer effect on skeleton items
  startShimmerEffect() {
    this.shimmerTargets.forEach(shimmer => {
      shimmer.classList.add('shimmer-active')
    })

    // Add shimmer to all skeleton elements
    this.skeletonTargets.forEach(skeleton => {
      skeleton.classList.add('shimmer-loading')
    })
  }

  // Show loading spinner with rotating messages
  showSpinnerLoading() {
    this.loadingSpinnerTargets.forEach(spinner => {
      spinner.classList.remove('hidden')
      spinner.classList.add('animate-spin')
    })

    this.rotateLoadingMessages()
  }

  // Rotate through loading messages
  rotateLoadingMessages() {
    if (this.loadingTextTargets.length === 0) return

    const updateMessage = () => {
      const message = this.loadingMessagesValue[this.currentMessageIndex]
      this.loadingTextTargets.forEach(target => {
        target.style.opacity = '0'
        setTimeout(() => {
          target.textContent = message
          target.style.opacity = '1'
        }, 150)
      })

      this.currentMessageIndex = (this.currentMessageIndex + 1) % this.loadingMessagesValue.length
    }

    updateMessage()
    this.messageInterval = setInterval(updateMessage, 1500)
  }

  // Show progress bar loading
  showProgressLoading(targetProgress = 100) {
    this.progressBarTargets.forEach(bar => {
      bar.classList.remove('hidden')
      bar.style.width = '0%'

      // Animate progress
      let progress = 0
      const increment = targetProgress / (this.progressDurationValue / 50)

      const progressInterval = setInterval(() => {
        progress += increment
        bar.style.width = `${Math.min(progress, targetProgress)}%`

        if (progress >= targetProgress) {
          clearInterval(progressInterval)
        }
      }, 50)
    })
  }

  // Complete loading and show content
  completeLoading() {
    // Fade out skeleton
    this.hideSkeletonLoading()

    // Hide spinners
    this.hideSpinnerLoading()

    // Complete progress bars
    this.completeProgressBars()

    // Show content with staggered animation
    setTimeout(() => {
      this.showContent()
    }, this.durationValue)
  }

  hideSkeletonLoading() {
    this.skeletonTargets.forEach((skeleton, index) => {
      setTimeout(() => {
        skeleton.style.transition = 'opacity 0.3s ease-out, transform 0.3s ease-out'
        skeleton.style.opacity = '0'
        skeleton.style.transform = 'translateY(-10px)'

        setTimeout(() => {
          skeleton.classList.add('hidden')
          skeleton.classList.remove('shimmer-loading')
        }, 300)
      }, index * 50)
    })

    // Stop shimmer effect
    this.shimmerTargets.forEach(shimmer => {
      shimmer.classList.remove('shimmer-active')
    })
  }

  hideSpinnerLoading() {
    this.loadingSpinnerTargets.forEach(spinner => {
      spinner.style.transition = 'opacity 0.3s ease-out'
      spinner.style.opacity = '0'
      setTimeout(() => {
        spinner.classList.add('hidden')
        spinner.classList.remove('animate-spin')
        spinner.style.opacity = '1'
      }, 300)
    })

    // Clear message rotation
    if (this.messageInterval) {
      clearInterval(this.messageInterval)
    }
  }

  completeProgressBars() {
    this.progressBarTargets.forEach(bar => {
      bar.style.width = '100%'
      setTimeout(() => {
        bar.style.transition = 'opacity 0.3s ease-out'
        bar.style.opacity = '0'
        setTimeout(() => {
          bar.classList.add('hidden')
          bar.style.opacity = '1'
        }, 300)
      }, 500)
    })
  }

  showContent() {
    this.contentTargets.forEach((content, index) => {
      setTimeout(() => {
        content.style.transition = 'opacity 0.4s ease-out, transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)'
        content.style.opacity = '1'
        content.style.transform = 'translateY(0)'
      }, index * 100)
    })

    // Add celebration for content appearance
    setTimeout(() => {
      this.triggerContentCelebration()
    }, this.contentTargets.length * 100 + 200)
  }

  triggerContentCelebration() {
    // Add subtle success indicators
    this.contentTargets.forEach(content => {
      content.classList.add('content-loaded')

      // Remove celebration class after animation
      setTimeout(() => {
        content.classList.remove('content-loaded')
      }, 600)
    })
  }

  // Quick loading state for fast transitions
  showQuickLoading() {
    this.element.classList.add('quick-loading')

    setTimeout(() => {
      this.element.classList.remove('quick-loading')
    }, 500)
  }

  // Pulse loading for interactive elements
  showPulseLoading() {
    this.pulseItemTargets.forEach((item, index) => {
      setTimeout(() => {
        item.classList.add('pulse-loading')
      }, index * 100)
    })
  }

  hidePulseLoading() {
    this.pulseItemTargets.forEach(item => {
      item.classList.remove('pulse-loading')
    })
  }

  // Fade container for smooth transitions between states
  fadeOut(callback) {
    this.fadeContainerTargets.forEach(container => {
      container.style.transition = 'opacity 0.3s ease-out'
      container.style.opacity = '0'
    })

    setTimeout(() => {
      if (callback) callback()
    }, 300)
  }

  fadeIn() {
    this.fadeContainerTargets.forEach(container => {
      container.style.transition = 'opacity 0.3s ease-out'
      container.style.opacity = '1'
    })
  }

  // Action methods for manual control
  startLoading(event) {
    const loadingType = event.params?.type || 'skeleton'

    switch (loadingType) {
      case 'skeleton':
        this.showSkeletonLoading()
        break
      case 'spinner':
        this.showSpinnerLoading()
        break
      case 'progress':
        this.showProgressLoading()
        break
      case 'pulse':
        this.showPulseLoading()
        break
      case 'quick':
        this.showQuickLoading()
        break
    }
  }

  stopLoading(event) {
    this.completeLoading()
  }

  disconnect() {
    if (this.messageInterval) {
      clearInterval(this.messageInterval)
    }
  }
}

// Inject CSS for loading animations
const style = document.createElement('style')
style.textContent = `
  /* Skeleton loading animations */
  .skeleton-item {
    background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
    background-size: 200% 100%;
    animation: loading-skeleton 1.5s infinite;
  }

  .dark .skeleton-item {
    background: linear-gradient(90deg, #374151 25%, #4b5563 50%, #374151 75%);
    background-size: 200% 100%;
  }

  @keyframes loading-skeleton {
    0% {
      background-position: 200% 0;
    }
    100% {
      background-position: -200% 0;
    }
  }

  /* Shimmer effect */
  .shimmer-loading {
    position: relative;
    overflow: hidden;
  }

  .shimmer-loading::after {
    content: '';
    position: absolute;
    top: 0;
    right: 0;
    bottom: 0;
    left: 0;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.4), transparent);
    transform: translateX(-100%);
    animation: shimmer 1.5s infinite;
  }

  @keyframes shimmer {
    100% {
      transform: translateX(100%);
    }
  }

  /* Content loaded celebration */
  .content-loaded {
    animation: contentAppear 0.6s ease-out;
  }

  @keyframes contentAppear {
    0% {
      transform: scale(0.95);
    }
    50% {
      transform: scale(1.02);
    }
    100% {
      transform: scale(1);
    }
  }

  /* Quick loading indicator */
  .quick-loading {
    position: relative;
  }

  .quick-loading::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(90deg, #ec4899, #f59e0b, #ec4899);
    background-size: 200% 100%;
    animation: quickLoading 0.5s ease-in-out;
    z-index: 10;
  }

  @keyframes quickLoading {
    0% {
      background-position: 200% 0;
    }
    100% {
      background-position: -200% 0;
    }
  }

  /* Pulse loading */
  .pulse-loading {
    animation: pulse-loading 1.5s ease-in-out infinite;
  }

  @keyframes pulse-loading {
    0%, 100% {
      opacity: 1;
      transform: scale(1);
    }
    50% {
      opacity: 0.7;
      transform: scale(0.98);
    }
  }

  /* Reduced motion support */
  @media (prefers-reduced-motion: reduce) {
    .skeleton-item,
    .shimmer-loading::after,
    .content-loaded,
    .quick-loading::before,
    .pulse-loading {
      animation: none !important;
    }

    .content-loaded {
      transform: none !important;
    }
  }
`
document.head.appendChild(style)