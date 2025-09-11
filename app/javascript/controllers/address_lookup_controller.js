import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="address-lookup"
export default class extends Controller {
  static targets = ["postalCode", "streetAddress", "city", "state", "country", "lookupButton"]
  static values = { 
    lookupUrl: String,
    csrfToken: String 
  }

  connect() {
    // Bind the lookup method to preserve context
    this.lookupAddress = this.lookupAddress.bind(this)
  }

  async lookupAddress() {
    const postalCode = this.postalCodeTarget.value.trim()
    if (!postalCode) {
      this.showError("Please enter a postal code")
      return
    }

    // Clear any existing messages
    this.clearMessages()
    
    // Show loading state
    this.setLoadingState(true)
    
    try {
      const response = await fetch(this.lookupUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfTokenValue,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          postal_code: postalCode
          // Country is now auto-detected by the service
        })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.populateAddressFields(data.data)
        this.showSuccess("Address found and populated!")
      } else {
        this.showError(data.error || "Address lookup failed")
      }
    } catch (error) {
      console.error('Address lookup error:', error)
      this.showError("Address lookup service unavailable")
    } finally {
      this.setLoadingState(false)
    }
  }

  populateAddressFields(addressData) {
    if (addressData.street_address && this.hasStreetAddressTarget) {
      this.streetAddressTarget.value = addressData.street_address
    }
    
    if (addressData.city && this.hasCityTarget) {
      this.cityTarget.value = addressData.city
    }
    
    if (addressData.state && this.hasStateTarget) {
      this.stateTarget.value = addressData.state
    }
    
    if (addressData.country && this.hasCountryTarget) {
      this.countryTarget.value = addressData.country
    }

    // Trigger change events for form validation
    const allTargets = [
      this.streetAddressTarget,
      this.cityTarget, 
      this.stateTarget,
      this.countryTarget
    ].filter(target => target)
    
    allTargets.forEach(target => {
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT') {
        target.dispatchEvent(new Event('input', { bubbles: true }))
        target.dispatchEvent(new Event('change', { bubbles: true }))
      }
    })
  }

  setLoadingState(isLoading) {
    if (this.hasLookupButtonTarget) {
      const button = this.lookupButtonTarget
      if (isLoading) {
        button.disabled = true
        button.innerHTML = this.getLoadingHTML()
      } else {
        button.disabled = false
        button.innerHTML = this.getDefaultButtonHTML()
      }
    }
  }

  clearMessages() {
    // Remove existing tooltips from document body
    const existingTooltips = document.querySelectorAll('.address-lookup-message')
    existingTooltips.forEach(tooltip => tooltip.remove())
  }

  showError(message) {
    this.showMessage(message, 'error')
  }

  showSuccess(message) {
    this.showMessage(message, 'success')
  }

  showMessage(message, type) {
    // Remove existing tooltips
    this.clearMessages()
    
    // Create tooltip
    const tooltip = document.createElement('div')
    const tooltipId = 'address-lookup-tooltip-' + Date.now()
    tooltip.id = tooltipId
    tooltip.className = `address-lookup-message fixed z-50 px-3 py-2 text-sm font-medium rounded-lg shadow-lg ${this.getTooltipClasses(type)} flex items-center gap-2 transform -translate-x-1/2 pointer-events-none`
    
    // Add icon based on type
    const icon = type === 'error' ? 
      '<svg class="w-4 h-4 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>' :
      '<svg class="w-4 h-4 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>'
    
    tooltip.innerHTML = `${icon}<span>${message}</span>`
    
    // Position tooltip above the button
    document.body.appendChild(tooltip)
    
    if (this.hasLookupButtonTarget) {
      const buttonRect = this.lookupButtonTarget.getBoundingClientRect()
      tooltip.style.left = (buttonRect.left + buttonRect.width / 2) + 'px'
      tooltip.style.top = (buttonRect.top - tooltip.offsetHeight - 8) + 'px'
    }
    
    // Add entrance animation
    setTimeout(() => {
      tooltip.classList.add('opacity-100')
      tooltip.classList.remove('opacity-0')
    }, 10)
    
    // Auto-remove tooltip after delay
    const removeDelay = type === 'success' ? 3000 : 5000
    setTimeout(() => {
      if (tooltip.parentNode) {
        tooltip.classList.add('opacity-0')
        setTimeout(() => tooltip.remove(), 200)
      }
    }, removeDelay)
  }

  getTooltipClasses(type) {
    switch (type) {
      case 'error':
        return 'bg-red-600 text-white opacity-0 transition-opacity duration-200'
      case 'success':
        return 'bg-green-600 text-white opacity-0 transition-opacity duration-200'
      default:
        return 'bg-blue-600 text-white opacity-0 transition-opacity duration-200'
    }
  }

  detectCountryFromLocale() {
    // Detect country based on current locale
    const locale = document.documentElement.lang || 'en'
    return locale.includes('pt-BR') ? 'BR' : 'US'
  }

  getLoadingHTML() {
    return `
      <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Loading...
    `
  }

  getDefaultButtonHTML() {
    const locale = document.documentElement.lang || 'en'
    if (locale.includes('pt-BR')) {
      return `
        <svg class="w-4 h-4 mr-1.5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
        Buscar Endereço
      `
    } else {
      return `
        <svg class="w-4 h-4 mr-1.5 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
        </svg>
        Lookup Address
      `
    }
  }
}