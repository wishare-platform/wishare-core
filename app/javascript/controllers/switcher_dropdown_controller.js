import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="switcher-dropdown"
export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    // Bind the close method to this instance so we can use it as an event listener
    this.boundClose = this.close.bind(this)
  }

  disconnect() {
    // Clean up event listener if it exists
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()

    const isOpen = this.menuTarget.classList.contains("show")

    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("show")

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "true")
    }

    // Close dropdown when clicking outside
    // Use setTimeout to prevent immediate closure from the same click event
    setTimeout(() => {
      document.addEventListener("click", this.boundClose, { once: true })
    }, 10)
  }

  close() {
    this.menuTarget.classList.remove("show")

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", "false")
    }

    // Remove event listener
    document.removeEventListener("click", this.boundClose)
  }

  // Close dropdown when clicking on a menu item
  closeOnSelect(event) {
    // Allow the link to navigate before closing
    setTimeout(() => {
      this.close()
    }, 100)
  }
}
