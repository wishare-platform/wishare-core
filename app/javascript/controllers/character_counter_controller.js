import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="character-counter"
export default class extends Controller {
  static targets = ["count"]
  static values = { max: Number }

  connect() {
    this.updateCount()
  }

  updateCount() {
    // Find the textarea within this controller's element
    const textarea = this.element.querySelector('textarea')
    const length = textarea ? textarea.value.length : 0
    this.countTarget.textContent = length

    // Add warning color when approaching limit
    if (length > this.maxValue * 0.9) {
      this.countTarget.classList.add("text-red-500", "dark:text-red-400")
      this.countTarget.classList.remove("text-gray-500", "dark:text-gray-400")
    } else {
      this.countTarget.classList.remove("text-red-500", "dark:text-red-400")
      this.countTarget.classList.add("text-gray-500", "dark:text-gray-400")
    }
  }

  // Called on every keystroke
  input() {
    this.updateCount()
  }
}