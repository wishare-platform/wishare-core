import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lengthCheck", "numberCheck", "symbolCheck", "caseCheck"]

  checkRequirements(event) {
    const password = event.target.value

    // Check length (at least 8 characters)
    if (password.length >= 8) {
      this.lengthCheckTarget.classList.remove('text-gray-400')
      this.lengthCheckTarget.classList.add('text-green-500')
    } else {
      this.lengthCheckTarget.classList.remove('text-green-500')
      this.lengthCheckTarget.classList.add('text-gray-400')
    }

    // Check for number
    if (/\d/.test(password)) {
      this.numberCheckTarget.classList.remove('text-gray-400')
      this.numberCheckTarget.classList.add('text-green-500')
    } else {
      this.numberCheckTarget.classList.remove('text-green-500')
      this.numberCheckTarget.classList.add('text-gray-400')
    }

    // Check for special character
    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
      this.symbolCheckTarget.classList.remove('text-gray-400')
      this.symbolCheckTarget.classList.add('text-green-500')
    } else {
      this.symbolCheckTarget.classList.remove('text-green-500')
      this.symbolCheckTarget.classList.add('text-gray-400')
    }

    // Check for uppercase and lowercase
    if (/[a-z]/.test(password) && /[A-Z]/.test(password)) {
      this.caseCheckTarget.classList.remove('text-gray-400')
      this.caseCheckTarget.classList.add('text-green-500')
    } else {
      this.caseCheckTarget.classList.remove('text-green-500')
      this.caseCheckTarget.classList.add('text-gray-400')
    }
  }
}