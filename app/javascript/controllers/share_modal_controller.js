import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { title: String, url: String, description: String }

  connect() {
    this.createModal()
  }

  open() {
    this.createModal()
    
    const modal = document.getElementById("share-modal")
    const titleElement = modal.querySelector('[data-share-modal-target="title"]')
    const urlElement = modal.querySelector('[data-share-modal-target="url"]')
    const descriptionElement = modal.querySelector('[data-share-modal-target="description"]')
    
    if (titleElement && urlElement && descriptionElement) {
      titleElement.textContent = this.titleValue
      urlElement.textContent = this.urlValue
      descriptionElement.textContent = this.descriptionValue
      
      // Show modal
      modal.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }
  }

  close() {
    const modal = document.getElementById("share-modal")
    if (modal) {
      modal.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  createModal() {
    if (document.getElementById("share-modal")) return
    
    const modal = document.createElement("div")
    modal.id = "share-modal"
    modal.className = "hidden fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.close()
    })
    
    modal.innerHTML = `
      <div class="bg-white dark:bg-gray-800 rounded-2xl p-6 w-full max-w-md" onclick="event.stopPropagation()">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Share</h3>
          <button type="button" id="close-share-modal" class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 cursor-pointer">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        
        <div class="mb-6">
          <h4 data-share-modal-target="title" class="font-medium text-gray-900 dark:text-gray-100 mb-2"></h4>
          <p data-share-modal-target="description" class="text-sm text-gray-600 dark:text-gray-400 mb-3"></p>
          <div class="bg-gray-100 dark:bg-gray-700 rounded-lg p-3">
            <code data-share-modal-target="url" class="text-xs text-gray-800 dark:text-gray-200 break-all"></code>
          </div>
        </div>
        
        <div class="grid grid-cols-2 gap-3 mb-4">
          <button type="button" id="share-whatsapp" class="flex items-center gap-2 p-3 bg-green-500 hover:bg-green-600 text-white rounded-lg transition duration-200 cursor-pointer">
            <span class="text-lg">📱</span>
            <span class="font-medium">WhatsApp</span>
          </button>
          
          <button type="button" id="share-twitter" class="flex items-center gap-2 p-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition duration-200 cursor-pointer">
            <span class="text-lg">🐦</span>
            <span class="font-medium">Twitter</span>
          </button>
          
          <button type="button" id="share-facebook" class="flex items-center gap-2 p-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition duration-200 cursor-pointer">
            <span class="text-lg">📘</span>
            <span class="font-medium">Facebook</span>
          </button>
          
          <button type="button" id="share-linkedin" class="flex items-center gap-2 p-3 bg-blue-700 hover:bg-blue-800 text-white rounded-lg transition duration-200 cursor-pointer">
            <span class="text-lg">💼</span>
            <span class="font-medium">LinkedIn</span>
          </button>
          
          <button type="button" id="share-telegram" class="flex items-center gap-2 p-3 bg-blue-400 hover:bg-blue-500 text-white rounded-lg transition duration-200 cursor-pointer">
            <span class="text-lg">✈️</span>
            <span class="font-medium">Telegram</span>
          </button>
          
          <button type="button" id="share-copy" class="flex items-center gap-2 p-3 bg-gray-600 dark:bg-gray-700 hover:bg-gray-700 dark:hover:bg-gray-600 text-white rounded-lg transition duration-200 cursor-pointer">
            <span class="text-lg">🔗</span>
            <span class="font-medium">Copy Link</span>
          </button>
        </div>
      </div>
    `
    
    document.body.appendChild(modal)
    
    // Add event listeners
    modal.querySelector('#close-share-modal').addEventListener('click', () => this.close())
    modal.querySelector('#share-whatsapp').addEventListener('click', () => this.shareWhatsApp())
    modal.querySelector('#share-twitter').addEventListener('click', () => this.shareTwitter())
    modal.querySelector('#share-facebook').addEventListener('click', () => this.shareFacebook())
    modal.querySelector('#share-linkedin').addEventListener('click', () => this.shareLinkedIn())
    modal.querySelector('#share-telegram').addEventListener('click', () => this.shareTelegram())
    modal.querySelector('#share-copy').addEventListener('click', () => this.copyLink())
  }

  updateShareButtons() {
    // This method can be extended to update share button URLs dynamically
  }

  clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  shareWhatsApp() {
    this.showShareFeedback('share-whatsapp', '📱', 'Opening...')
    const text = `${this.titleValue} - ${this.urlValue}`
    const url = `https://wa.me/?text=${encodeURIComponent(text)}`
    setTimeout(() => window.open(url, '_blank', 'noopener,noreferrer'), 500)
  }

  shareTwitter() {
    this.showShareFeedback('share-twitter', '🐦', 'Opening...')
    const text = `${this.titleValue} - ${this.descriptionValue}`
    const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(this.urlValue)}`
    setTimeout(() => window.open(url, '_blank', 'noopener,noreferrer'), 500)
  }

  shareFacebook() {
    this.showShareFeedback('share-facebook', '📘', 'Opening...')
    const url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.urlValue)}`
    setTimeout(() => window.open(url, '_blank', 'noopener,noreferrer'), 500)
  }

  shareLinkedIn() {
    this.showShareFeedback('share-linkedin', '💼', 'Opening...')
    const url = `https://www.linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(this.urlValue)}`
    setTimeout(() => window.open(url, '_blank', 'noopener,noreferrer'), 500)
  }

  shareTelegram() {
    this.showShareFeedback('share-telegram', '✈️', 'Opening...')
    const text = `${this.titleValue}\n\n${this.descriptionValue}`
    const url = `https://t.me/share/url?url=${encodeURIComponent(this.urlValue)}&text=${encodeURIComponent(text)}`
    setTimeout(() => window.open(url, '_blank', 'noopener,noreferrer'), 500)
  }

  showShareFeedback(buttonId, icon, text) {
    const modal = document.getElementById("share-modal")
    const button = modal?.querySelector(`#${buttonId}`)
    if (button) {
      const originalContent = button.innerHTML
      const originalClasses = button.className
      
      // Show loading state
      button.innerHTML = `<span class="text-lg">${icon}</span><span class="font-medium">${text}</span>`
      button.className = originalClasses.replace('cursor-pointer', 'cursor-wait')
      button.style.transform = 'scale(0.95)'
      
      // Reset after delay
      setTimeout(() => {
        button.innerHTML = originalContent
        button.className = originalClasses
        button.style.transform = ''
      }, 600)
    }
  }

  copyLink() {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(this.urlValue).then(() => {
        this.showCopySuccess()
      }).catch(() => {
        this.fallbackCopy()
      })
    } else {
      this.fallbackCopy()
    }
  }

  fallbackCopy() {
    const textArea = document.createElement("textarea")
    textArea.value = this.urlValue
    textArea.style.position = "fixed"
    textArea.style.left = "-999999px"
    textArea.style.top = "-999999px"
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()
    
    try {
      document.execCommand('copy')
      this.showCopySuccess()
    } catch (err) {
      this.showCopyError()
    } finally {
      document.body.removeChild(textArea)
    }
  }

  showCopySuccess() {
    // Find the copy button and update it temporarily
    const modal = document.getElementById("share-modal")
    const copyButton = modal?.querySelector('#share-copy')
    if (copyButton) {
      const originalContent = copyButton.innerHTML
      const originalClasses = copyButton.className
      
      // Show success state with animation
      copyButton.innerHTML = '<span class="text-lg">✅</span><span class="font-medium">Copied!</span>'
      copyButton.className = 'flex items-center gap-2 p-3 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-all duration-300 cursor-pointer transform scale-105'
      
      // Add bounce animation
      copyButton.style.transform = 'scale(1.05)'
      
      setTimeout(() => {
        copyButton.style.transform = 'scale(1)'
      }, 150)
      
      setTimeout(() => {
        copyButton.innerHTML = originalContent
        copyButton.className = originalClasses
        copyButton.style.transform = ''
      }, 2500)
    }
  }

  showCopyError() {
    const modal = document.getElementById("share-modal")
    const copyButton = modal?.querySelector('#share-copy')
    if (copyButton) {
      const originalContent = copyButton.innerHTML
      const originalClasses = copyButton.className
      
      // Show error state with shake animation
      copyButton.innerHTML = '<span class="text-lg">❌</span><span class="font-medium">Failed</span>'
      copyButton.className = 'flex items-center gap-2 p-3 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-all duration-300 cursor-pointer'
      
      // Add shake animation
      copyButton.style.animation = 'shake 0.5s ease-in-out'
      
      setTimeout(() => {
        copyButton.innerHTML = originalContent
        copyButton.className = originalClasses
        copyButton.style.animation = ''
      }, 2500)
    }
  }
}