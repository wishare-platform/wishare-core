import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submitButton", "googleButton"]
  
  connect() {
    // Set initial state
    this.toggle()
  }
  
  toggle() {
    const isChecked = this.checkboxTarget.checked
    
    // Toggle submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !isChecked
      if (isChecked) {
        this.submitButtonTarget.className = "w-full bg-gradient-to-r from-rose-500 to-rose-600 text-white py-4 px-6 rounded-xl hover:from-rose-600 hover:to-rose-700 focus:outline-none focus:ring-2 focus:ring-rose-500 focus:ring-offset-2 transition duration-200 cursor-pointer font-semibold text-lg touch-manipulation shadow-lg"
      } else {
        this.submitButtonTarget.className = "w-full bg-gray-300 text-gray-500 py-4 px-6 rounded-xl cursor-not-allowed font-semibold text-lg shadow-lg opacity-50"
      }
    }
    
    // Toggle Google button
    if (this.hasGoogleButtonTarget) {
      this.googleButtonTarget.disabled = !isChecked
      if (isChecked) {
        this.googleButtonTarget.className = "w-full flex justify-center items-center px-6 py-4 border-2 border-rose-200 rounded-xl shadow-sm text-base font-medium text-gray-700 bg-white hover:bg-rose-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-rose-400 transition duration-200 touch-manipulation"
      } else {
        this.googleButtonTarget.className = "w-full flex justify-center items-center px-6 py-4 border-2 border-gray-200 rounded-xl shadow-sm text-base font-medium text-gray-400 bg-gray-50 cursor-not-allowed transition duration-200 opacity-50"
      }
    }
  }
}