import { Controller } from "@hotwired/stimulus"

// Lazy Loading Controller for Mobile Performance
export default class extends Controller {
  static targets = ["image", "content"]

  connect() {
    this.setupIntersectionObserver()
  }

  setupIntersectionObserver() {
    // Create intersection observer for lazy loading
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.loadContent(entry.target)
          this.observer.unobserve(entry.target)
        }
      })
    }, {
      rootMargin: '50px 0px', // Load 50px before element enters viewport
      threshold: 0.1
    })

    // Observe all lazy load targets
    this.imageTargets.forEach(img => {
      this.observer.observe(img)
    })

    this.contentTargets.forEach(content => {
      this.observer.observe(content)
    })
  }

  loadContent(element) {
    if (element.hasAttribute('data-lazy-src')) {
      // Load lazy image
      this.loadImage(element)
    } else if (element.hasAttribute('data-lazy-content')) {
      // Load lazy content
      this.loadLazyContent(element)
    }
  }

  loadImage(img) {
    const src = img.getAttribute('data-lazy-src')
    const placeholder = img.getAttribute('data-placeholder')

    // Add loading class
    img.classList.add('loading')

    // Create new image to test loading
    const newImg = new Image()
    newImg.onload = () => {
      img.src = src
      img.classList.remove('loading')
      img.classList.add('loaded')

      // Add fade-in animation
      img.style.opacity = '0'
      img.style.transition = 'opacity 0.3s ease-in-out'

      requestAnimationFrame(() => {
        img.style.opacity = '1'
      })
    }

    newImg.onerror = () => {
      img.classList.remove('loading')
      img.classList.add('error')
      // Keep placeholder or show error state
    }

    newImg.src = src
  }

  loadLazyContent(element) {
    const url = element.getAttribute('data-lazy-content')

    // Show loading state
    element.innerHTML = `
      <div class="flex items-center justify-center p-4">
        <svg class="animate-spin w-5 h-5 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
        <span class="ml-2 text-sm text-gray-500">Loading...</span>
      </div>
    `

    // Fetch content
    fetch(url)
      .then(response => response.text())
      .then(html => {
        element.innerHTML = html
        element.classList.add('loaded')

        // Trigger any new Stimulus controllers in loaded content
        this.application.load(element)
      })
      .catch(error => {
        element.innerHTML = `
          <div class="text-center p-4 text-gray-500">
            <p class="text-sm">Failed to load content</p>
            <button class="text-rose-500 text-xs mt-1" onclick="this.parentElement.parentElement.click()">
              Retry
            </button>
          </div>
        `
      })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }
}