import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="postal-code-lookup"
export default class extends Controller {
  static targets = ["input", "loading", "error", "country", "street", "city", "state"]
  static values = {
    lookupUrl: String,
    csrfToken: String
  }

  connect() {
    this.lookupTimeout = null

    // Set default lookup URL if not provided
    if (!this.lookupUrlValue) {
      this.lookupUrlValue = '/address_lookups/lookup'
    }

    // Get CSRF token if not provided
    if (!this.csrfTokenValue) {
      const token = document.querySelector('meta[name="csrf-token"]')
      if (token) {
        this.csrfTokenValue = token.getAttribute('content')
      }
    }
  }

  validateAndLookup() {
    const value = this.inputTarget.value

    // Clear previous error
    this.hideError()

    // Remove non-numeric characters and validate
    const numericValue = value.replace(/\D/g, '')

    // Update input with formatted value, preserving cursor position
    const cursorPosition = this.inputTarget.selectionStart
    const originalLength = value.length
    const formattedValue = this.formatPostalCode(numericValue)
    this.inputTarget.value = formattedValue
    const newLength = formattedValue.length

    // Restore cursor position accounting for formatting changes
    const newCursorPosition = cursorPosition + (newLength - originalLength)
    this.inputTarget.setSelectionRange(newCursorPosition, newCursorPosition)

    // Validate format
    if (numericValue.length > 0 && !this.isValidPostalCode(numericValue)) {
      this.showError("Invalid postal/ZIP code format")
      return
    }

    // Perform lookup if valid and complete
    if (this.isCompletePostalCode(numericValue)) {
      // Clear previous timeout
      if (this.lookupTimeout) {
        clearTimeout(this.lookupTimeout)
      }

      // Debounce lookup calls
      this.lookupTimeout = setTimeout(() => {
        this.performLookup(numericValue)
      }, 500)
    }
  }

  isValidPostalCode(numericValue) {
    // US ZIP: 5 or 9 digits
    // Brazil CEP: 8 digits
    // Canada: 6 digits (but includes letters, handle separately)
    return numericValue.length <= 9 && /^\d+$/.test(numericValue)
  }

  isCompletePostalCode(numericValue) {
    // Consider complete when we have 5 digits (US ZIP) or 8 digits (Brazil CEP)
    return numericValue.length === 5 || numericValue.length === 8
  }

  formatPostalCode(numericValue) {
    // Format based on length
    if (numericValue.length === 8) {
      // Brazilian CEP format: 12345-678
      return numericValue.replace(/(\d{5})(\d{3})/, '$1-$2')
    } else if (numericValue.length === 9) {
      // US ZIP+4 format: 12345-6789
      return numericValue.replace(/(\d{5})(\d{4})/, '$1-$2')
    } else if (numericValue.length === 5) {
      // US ZIP format: 12345 (no formatting needed)
      return numericValue
    }
    return numericValue
  }

  async performLookup(postalCode) {
    this.showLoading()
    this.hideError()

    // Send the formatted postal code to the API
    const formattedCode = this.formatPostalCode(postalCode)

    try {
      const response = await fetch(this.lookupUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfTokenValue,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          postal_code: formattedCode
        })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.populateAddressFields(data.data)
      } else {
        this.showError(data.error || "Address not found")
      }
    } catch (error) {
      console.error('Address lookup error:', error)
      this.showError("Address lookup service unavailable")
    } finally {
      this.hideLoading()
    }
  }

  populateAddressFields(addressData) {
    console.log('Populating fields with data:', addressData)

    // Update country if available
    if (addressData.country && this.hasCountryTarget) {
      this.countryTarget.value = addressData.country
      this.countryTarget.dispatchEvent(new Event('change', { bubbles: true }))
    }

    // Update street address if available and not already filled
    if (addressData.street_address && this.hasStreetTarget && !this.streetTarget.value.trim()) {
      this.streetTarget.value = addressData.street_address
      this.streetTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Update city if available
    if (addressData.city && this.hasCityTarget) {
      this.cityTarget.value = addressData.city
      this.cityTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Update state if available
    if (addressData.state && this.hasStateTarget) {
      this.stateTarget.value = addressData.state
      this.stateTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }

    // Focus on apartment/complement field after successful population
    this.focusOnComplementField()
  }

  focusOnComplementField() {
    // Prioritize focusing on the first empty required field
    const streetNumberField = document.querySelector('input[name*="street_number"]')
    const apartmentField = document.querySelector('input[name*="apartment"]')

    let fieldToFocus = null

    // If street number is empty, focus there first (most important for US addresses)
    if (streetNumberField && !streetNumberField.value.trim()) {
      fieldToFocus = streetNumberField
    }
    // Otherwise focus on apartment/complement field
    else if (apartmentField && !apartmentField.value.trim()) {
      fieldToFocus = apartmentField
    }

    if (fieldToFocus) {
      setTimeout(() => {
        fieldToFocus.focus()
        fieldToFocus.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }, 300)
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'flex'
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.style.display = 'none'
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.style.display = 'block'
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = 'none'
    }
  }

  disconnect() {
    if (this.lookupTimeout) {
      clearTimeout(this.lookupTimeout)
    }
  }
}