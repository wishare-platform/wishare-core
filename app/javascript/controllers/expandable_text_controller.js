import { Controller } from "@hotwired/stimulus"

// Expandable Text Controller for Mobile Content
export default class extends Controller {
  static targets = ["content", "toggleBtn"]
  static values = { limit: Number }

  connect() {
    this.originalText = this.contentTarget.textContent.trim()
    this.isExpanded = false

    if (this.originalText.length > this.limitValue) {
      this.collapse()
    }
  }

  toggle() {
    if (this.isExpanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.contentTarget.textContent = this.originalText
    this.toggleBtnTarget.textContent = "Show less"
    this.isExpanded = true
  }

  collapse() {
    const truncatedText = this.originalText.substring(0, this.limitValue) + "..."
    this.contentTarget.textContent = truncatedText
    this.toggleBtnTarget.textContent = "Show more"
    this.isExpanded = false
  }
}