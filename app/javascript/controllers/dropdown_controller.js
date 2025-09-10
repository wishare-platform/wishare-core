import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    
    // Adjust positioning based on viewport space
    if (!this.menuTarget.classList.contains("hidden")) {
      const rect = this.menuTarget.getBoundingClientRect()
      const windowHeight = window.innerHeight
      const spaceBelow = windowHeight - rect.top
      
      // If dropdown extends below viewport, position it above the button
      if (spaceBelow < rect.height + 20) {
        this.menuTarget.classList.add("bottom-full", "mb-2")
        this.menuTarget.classList.remove("mt-2")
      } else {
        this.menuTarget.classList.remove("bottom-full", "mb-2")
        this.menuTarget.classList.add("mt-2")
      }
    }
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.hide.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.hide.bind(this))
  }
}