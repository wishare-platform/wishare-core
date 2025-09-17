import { Controller } from "@hotwired/stimulus"

// Mobile Collapsible Controller for Dashboard Sections
export default class extends Controller {
  static targets = ["content", "chevron", "preview"]
  static values = { key: String }

  connect() {
    // Restore state from localStorage
    const isExpanded = localStorage.getItem(`dashboard-mobile-${this.keyValue}-expanded`) === 'true'
    if (isExpanded) {
      this.expand()
    }
  }

  toggle() {
    if (this.contentTarget.classList.contains('hidden')) {
      this.expand()
    } else {
      this.collapse()
    }
  }

  expand() {
    this.contentTarget.classList.remove('hidden')
    this.chevronTarget.style.transform = 'rotate(180deg)'

    // Hide preview when expanded (if preview exists)
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = 'none'
    }

    // Save state
    localStorage.setItem(`dashboard-mobile-${this.keyValue}-expanded`, 'true')

    // Add smooth slide-down animation
    this.contentTarget.style.maxHeight = '0px'
    this.contentTarget.style.overflow = 'hidden'

    requestAnimationFrame(() => {
      this.contentTarget.style.transition = 'max-height 0.3s ease-out'
      this.contentTarget.style.maxHeight = `${this.contentTarget.scrollHeight}px`

      setTimeout(() => {
        this.contentTarget.style.maxHeight = 'none'
        this.contentTarget.style.overflow = 'visible'
      }, 300)
    })
  }

  collapse() {
    // Show preview when collapsed (if preview exists)
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = 'block'
    }

    // Add smooth slide-up animation
    this.contentTarget.style.maxHeight = `${this.contentTarget.scrollHeight}px`
    this.contentTarget.style.overflow = 'hidden'
    this.contentTarget.style.transition = 'max-height 0.3s ease-out'

    requestAnimationFrame(() => {
      this.contentTarget.style.maxHeight = '0px'

      setTimeout(() => {
        this.contentTarget.classList.add('hidden')
        this.contentTarget.style.maxHeight = 'none'
        this.contentTarget.style.overflow = 'visible'
        this.contentTarget.style.transition = 'none'
      }, 300)
    })

    this.chevronTarget.style.transform = 'rotate(0deg)'

    // Save state
    localStorage.setItem(`dashboard-mobile-${this.keyValue}-expanded`, 'false')
  }
}