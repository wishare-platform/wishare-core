import { Controller } from "@hotwired/stimulus"

// Simple Mobile Navigation Controller - No over-engineering
export default class extends Controller {
  connect() {
    // Just light haptic feedback for mobile
    if (window.innerWidth < 1024) {
      this.addHapticFeedback()
    }
  }

  addHapticFeedback() {
    const navLinks = this.element.querySelectorAll('a')

    navLinks.forEach(link => {
      link.addEventListener('touchstart', () => {
        if ('vibrate' in navigator) {
          navigator.vibrate(10)
        }
      })
    })
  }
}