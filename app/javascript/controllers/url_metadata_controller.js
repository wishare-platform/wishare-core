import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "name", "description", "price", "currency", "image", "loading", "success", "error", "fetching", "populated", "errorMessage", "imagePreview", "previewImage", "imageLoading", "imageError"]
  
  connect() {
    this.lastProcessedUrl = ''
    this.currentRequest = null
    console.log("URL metadata controller connected")
  }

  disconnect() {
    if (this.currentRequest) {
      this.currentRequest.abort()
    }
  }

  hasUrlMeaningfullyChanged(oldUrl, newUrl) {
    if (!oldUrl || !newUrl) return true
    
    try {
      const url1 = new URL(oldUrl)
      const url2 = new URL(newUrl)
      
      // Different domain or different path means meaningful change
      return url1.hostname !== url2.hostname || url1.pathname !== url2.pathname
    } catch (e) {
      // If URLs can't be parsed, consider it a meaningful change
      return true
    }
  }

  urlBlurred() {
    console.log("URL field blurred, processing...")
    // Small delay to ensure user has finished typing
    setTimeout(() => {
      if (this.urlTarget.value.trim()) {
        this.fetchUrlMetadata()
      } else {
        this.hideAllStatus()
      }
    }, 100)
  }

  urlKeyDown(event) {
    if (event.key === 'Enter') {
      event.preventDefault() // Prevent form submission
      this.urlTarget.blur() // Trigger blur event which will fetch metadata
    }
  }

  urlInput() {
    const currentUrl = this.urlTarget.value.trim()
    
    // Only clear status if URL has meaningfully changed from the last processed URL
    if (this.lastProcessedUrl && currentUrl !== this.lastProcessedUrl) {
      // Check if this is a significant change (not just adding/removing characters from same URL)
      const normalizedCurrent = currentUrl.toLowerCase().replace(/[\/\s]/g, '')
      const normalizedLast = this.lastProcessedUrl.toLowerCase().replace(/[\/\s]/g, '')
      
      // Clear status if URLs are significantly different (more than 3 character difference)
      const isDifferentUrl = Math.abs(normalizedCurrent.length - normalizedLast.length) > 3 ||
                             !normalizedCurrent.includes(normalizedLast.substring(0, Math.min(10, normalizedLast.length))) &&
                             !normalizedLast.includes(normalizedCurrent.substring(0, Math.min(10, normalizedCurrent.length)))
      
      if (isDifferentUrl) {
        this.hideAllStatus()
        this.lastProcessedUrl = '' // Reset so new URL can be processed
      }
    }
    
    // Always cancel ongoing request if URL changed
    if (currentUrl !== this.lastProcessedUrl && this.currentRequest) {
      this.currentRequest.abort()
      this.currentRequest = null
    }
  }

  imageInput() {
    clearTimeout(this.imageTimeout)
    const url = this.imageTarget.value.trim()
    
    if (!url) {
      this.hideImagePreview()
      return
    }
    
    // Debounce the preview update
    this.imageTimeout = setTimeout(() => {
      this.showImagePreview(url)
    }, 500)
  }

  imageBlurred() {
    const url = this.imageTarget.value.trim()
    if (url) {
      this.showImagePreview(url)
    }
  }

  fetchUrlMetadata() {
    const url = this.urlTarget.value.trim()
    
    console.log("Fetching metadata for URL:", url)
    
    // Don't fetch if URL is empty or invalid
    if (!url || !url.match(/^https?:\/\/.+/)) {
      console.log("Skipping fetch - invalid URL")
      return
    }
    
    // Check if this is the same URL we just processed
    if (url === this.lastProcessedUrl) {
      console.log("Skipping fetch - same URL already processed")
      return
    }
    
    // Check if URL has meaningfully changed (different domain or path)
    const urlChanged = this.hasUrlMeaningfullyChanged(this.lastProcessedUrl, url)
    
    // Only auto-populate if fields are empty OR if URL has meaningfully changed
    const fieldsEmpty = !this.nameTarget.value.trim() && 
                       !this.descriptionTarget.value.trim() && 
                       !this.priceTarget.value.trim() &&
                       !this.imageTarget.value.trim()
    
    if (!fieldsEmpty && !urlChanged) {
      console.log("Skipping fetch - fields already have values and URL hasn't meaningfully changed")
      return
    }
    
    // Cancel any ongoing request
    if (this.currentRequest) {
      this.currentRequest.abort()
      this.currentRequest = null
    }
    
    this.showLoading()
    this.lastProcessedUrl = url
    
    // Create AbortController for request cancellation
    const controller = new AbortController()
    this.currentRequest = controller
    
    // Build URL with current locale if present
    const currentPath = window.location.pathname
    const localeMatch = currentPath.match(/^\/(en|pt-BR)\//)
    const localePrefix = localeMatch ? `/${localeMatch[1]}` : ''
    
    const fetchUrl = `${localePrefix}/wishlist_items/extract_url_metadata`
    console.log("Fetching from:", fetchUrl)
    
    fetch(fetchUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ url: url }),
      signal: controller.signal
    })
    .then(response => {
      console.log("Response status:", response.status)
      if (!response.ok) {
        // Log more details about the error
        console.error('Fetch error:', response.status, response.statusText)
        return response.text().then(text => {
          console.error('Error response:', text)
          throw new Error(`Failed to fetch metadata: ${response.status} ${response.statusText}`)
        })
      }
      return response.json()
    })
    .then(data => {
      console.log("Received metadata:", data)
      this.currentRequest = null
      
      // Check if URL has meaningfully changed from what was previously processed
      const urlChanged = this.hasUrlMeaningfullyChanged(this.lastProcessedUrl, url)
      let populated = false
      
      // If URL has meaningfully changed, replace all fields with new data
      // Otherwise, only populate empty fields
      if (data.title && (!this.nameTarget.value.trim() || urlChanged)) {
        this.nameTarget.value = data.title
        populated = true
      }
      
      if (data.description && (!this.descriptionTarget.value.trim() || urlChanged)) {
        this.descriptionTarget.value = data.description
        populated = true
      }
      
      if (data.price && (!this.priceTarget.value.trim() || urlChanged)) {
        this.priceTarget.value = data.price
        populated = true
      }

      if (data.currency && this.hasCurrencyTarget && (!this.currencyTarget.value || urlChanged)) {
        this.currencyTarget.value = data.currency
        // Trigger the currency selector update to show correct symbol
        const event = new Event('change', { bubbles: true })
        this.currencyTarget.dispatchEvent(event)
        populated = true
      }
      
      if (data.image && (!this.imageTarget.value.trim() || urlChanged)) {
        this.imageTarget.value = data.image
        // Trigger image preview update
        this.showImagePreview(data.image)
        populated = true
      }
      
      if (populated) {
        this.showSuccess()
      } else {
        this.showError()
        // Hide error message after 4 seconds
        setTimeout(() => {
          if (this.hasErrorTarget && !this.errorTarget.classList.contains('hidden')) {
            this.hideAllStatus()
          }
        }, 4000)
      }
    })
    .catch(error => {
      console.error("Fetch error:", error)
      if (error.name !== 'AbortError') {
        this.currentRequest = null
        this.showError()
        // Hide error message after 4 seconds
        setTimeout(() => {
          if (this.hasErrorTarget && !this.errorTarget.classList.contains('hidden')) {
            this.hideAllStatus()
          }
        }, 4000)
      }
    })
  }

  hideAllStatus() {
    if (this.hasLoadingTarget) this.loadingTarget.classList.add('hidden')
    if (this.hasSuccessTarget) this.successTarget.classList.add('hidden')
    if (this.hasFetchingTarget) this.fetchingTarget.classList.add('hidden')
    if (this.hasPopulatedTarget) this.populatedTarget.classList.add('hidden')
    if (this.hasErrorTarget) this.errorTarget.classList.add('hidden')
    if (this.hasErrorMessageTarget) this.errorMessageTarget.classList.add('hidden')
  }

  showLoading() {
    this.hideAllStatus()
    if (this.hasLoadingTarget) this.loadingTarget.classList.remove('hidden')
    if (this.hasFetchingTarget) this.fetchingTarget.classList.remove('hidden')
    if (this.hasErrorMessageTarget) this.errorMessageTarget.classList.remove('hidden')
  }

  showSuccess() {
    this.hideAllStatus()
    if (this.hasSuccessTarget) this.successTarget.classList.remove('hidden')
    if (this.hasPopulatedTarget) this.populatedTarget.classList.remove('hidden')
    if (this.hasErrorMessageTarget) this.errorMessageTarget.classList.remove('hidden')
  }

  showError() {
    this.hideAllStatus()
    if (this.hasErrorTarget) this.errorTarget.classList.remove('hidden')
    if (this.hasErrorMessageTarget) this.errorMessageTarget.classList.remove('hidden')
  }

  showImagePreview(url) {
    if (!url || !url.match(/^https?:\/\/.+/)) {
      this.hideImagePreview()
      return
    }
    
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.classList.remove('hidden')
      if (this.hasImageLoadingTarget) this.imageLoadingTarget.classList.remove('hidden')
      if (this.hasImageErrorTarget) this.imageErrorTarget.classList.add('hidden')
      if (this.hasPreviewImageTarget) this.previewImageTarget.classList.add('hidden')
      
      // Create a new image element to test loading
      const testImage = new Image()
      
      testImage.onload = () => {
        if (this.hasPreviewImageTarget) {
          this.previewImageTarget.src = url
          this.previewImageTarget.classList.remove('hidden')
        }
        if (this.hasImageLoadingTarget) this.imageLoadingTarget.classList.add('hidden')
        if (this.hasImageErrorTarget) this.imageErrorTarget.classList.add('hidden')
      }
      
      testImage.onerror = () => {
        if (this.hasImageLoadingTarget) this.imageLoadingTarget.classList.add('hidden')
        if (this.hasImageErrorTarget) this.imageErrorTarget.classList.remove('hidden')
        if (this.hasPreviewImageTarget) this.previewImageTarget.classList.add('hidden')
      }
      
      testImage.src = url
    }
  }

  hideImagePreview() {
    if (this.hasImagePreviewTarget) {
      this.imagePreviewTarget.classList.add('hidden')
    }
  }
}