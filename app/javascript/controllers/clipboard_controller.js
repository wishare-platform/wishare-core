import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(this.textValue).then(() => {
        this.showSuccess()
      }).catch(() => {
        this.fallbackCopy()
      })
    } else {
      this.fallbackCopy()
    }
  }

  fallbackCopy() {
    const textArea = document.createElement("textarea")
    textArea.value = this.textValue
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showSuccess()
    } catch (err) {
      this.showError()
    } finally {
      document.body.removeChild(textArea)
    }
  }

  showSuccess() {
    const originalText = this.element.innerHTML
    const originalClasses = this.element.className
    
    // Show success state with animation
    this.element.innerHTML = '<span class="text-base">✅</span><span class="hidden sm:inline">Copied!</span>'
    this.element.className = 'inline-flex items-center gap-1 px-3 py-2 bg-green-500 hover:bg-green-600 text-white text-sm rounded-lg transition-all duration-300 cursor-pointer transform scale-105'
    
    // Add a subtle bounce animation
    this.element.style.transform = 'scale(1.05)'
    
    setTimeout(() => {
      this.element.style.transform = 'scale(1)'
    }, 150)
    
    setTimeout(() => {
      this.element.innerHTML = originalText
      this.element.className = originalClasses
      this.element.style.transform = ''
    }, 2500)
  }

  showError() {
    const originalText = this.element.innerHTML
    const originalClasses = this.element.className
    
    // Show error state with shake animation
    this.element.innerHTML = '<span class="text-base">❌</span><span class="hidden sm:inline">Failed</span>'
    this.element.className = 'inline-flex items-center gap-1 px-3 py-2 bg-red-500 hover:bg-red-600 text-white text-sm rounded-lg transition-all duration-300 cursor-pointer'
    
    // Add a shake animation
    this.element.style.animation = 'shake 0.5s ease-in-out'
    
    setTimeout(() => {
      this.element.innerHTML = originalText
      this.element.className = originalClasses
      this.element.style.animation = ''
    }, 2500)
  }
}