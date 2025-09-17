import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "indicator", "label"]

  check(event) {
    const password = event.target.value
    let strength = 0
    const strengthBars = this.indicatorTarget.querySelectorAll('div')

    // Calculate strength
    if (password.length >= 8) strength++
    if (password.match(/[a-z]/) && password.match(/[A-Z]/)) strength++
    if (password.match(/[0-9]/)) strength++
    if (password.match(/[^a-zA-Z0-9]/)) strength++

    // Update bars
    strengthBars.forEach((bar, index) => {
      bar.classList.remove('bg-red-500', 'bg-yellow-500', 'bg-blue-500', 'bg-green-500')
      if (index < strength) {
        bar.classList.remove('bg-gray-200', 'dark:bg-gray-600')
        if (strength === 1) bar.classList.add('bg-red-500')
        else if (strength === 2) bar.classList.add('bg-yellow-500')
        else if (strength === 3) bar.classList.add('bg-blue-500')
        else if (strength === 4) bar.classList.add('bg-green-500')
      } else {
        bar.classList.add('bg-gray-200', 'dark:bg-gray-600')
      }
    })

    // Update label if exists
    if (this.hasLabelTarget) {
      const labels = ['', 'Weak', 'Fair', 'Good', 'Strong']
      const colors = ['', 'text-red-500', 'text-yellow-500', 'text-blue-500', 'text-green-500']

      this.labelTarget.textContent = labels[strength]
      this.labelTarget.classList.remove('text-red-500', 'text-yellow-500', 'text-blue-500', 'text-green-500')
      if (strength > 0) {
        this.labelTarget.classList.add(colors[strength])
      }
    }
  }
}