import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "dropZone"]

  connect() {
    this.setupNativeBridge()
    this.setupDropZone()
  }

  setupNativeBridge() {
    // Setup native mobile camera integration
    if (window.NativeBridge) {
      this.nativeBridge = window.NativeBridge
    }
  }

  setupDropZone() {
    if (this.hasDropZoneTarget) {
      // Enable drag and drop
      this.dropZoneTarget.addEventListener('dragover', this.handleDragOver.bind(this))
      this.dropZoneTarget.addEventListener('drop', this.handleDrop.bind(this))
      this.dropZoneTarget.addEventListener('dragleave', this.handleDragLeave.bind(this))
    }
  }

  handleDragOver(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.add('border-rose-400', 'bg-rose-100', 'dark:bg-rose-900/40')
  }

  handleDragLeave(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove('border-rose-400', 'bg-rose-100', 'dark:bg-rose-900/40')
  }

  handleDrop(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove('border-rose-400', 'bg-rose-100', 'dark:bg-rose-900/40')

    const files = event.dataTransfer.files
    if (files.length > 0) {
      this.processFile(files[0])
    }
  }

  openFileDialog() {
    // Try native camera first (mobile apps)
    if (this.nativeBridge && this.nativeBridge.camera) {
      this.nativeBridge.camera.takePicture({
        quality: 0.8,
        maxWidth: 800,
        maxHeight: 400,
        allowEdit: true
      }).then(result => {
        if (result.success && result.imageData) {
          this.processImageData(result.imageData)
        }
      }).catch(error => {
        console.error('Native camera error:', error)
        // Fallback to file input
        this.inputTarget.click()
      })
    } else {
      this.inputTarget.click()
    }
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (file) {
      this.processFile(file)
    }
  }

  processFile(file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      return
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      alert('Image file size must be less than 5MB')
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.updatePreview(e.target.result)
    }
    reader.readAsDataURL(file)

    // Set the file to the input for form submission
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files
  }

  processImageData(imageData) {
    // For native mobile integration
    this.updatePreview(imageData)

    // Check if this is for a wishlist cover image and use native API if available
    const formElement = this.element.closest('form')
    const wishlistIdMatch = formElement?.action?.match(/wishlists\/(\d+)/)

    if (this.nativeBridge && this.nativeBridge.apiRequest && wishlistIdMatch) {
      const wishlistId = wishlistIdMatch[1]

      this.nativeBridge.apiRequest({
        url: `/api/v1/wishlists/${wishlistId}/cover-image`,
        method: 'POST',
        data: {
          cover_image_base64: imageData
        }
      }).then(response => {
        if (response.status === 'success') {
          console.log('Cover image updated via native API')
        } else {
          console.error('Native API upload failed:', response.message)
          this.fallbackImageProcessing(imageData)
        }
      }).catch(error => {
        console.error('Native API error:', error)
        this.fallbackImageProcessing(imageData)
      })
    } else {
      this.fallbackImageProcessing(imageData)
    }
  }

  fallbackImageProcessing(imageData) {
    // Convert base64 to blob and set to input for form submission
    fetch(imageData)
      .then(response => response.blob())
      .then(blob => {
        const file = new File([blob], 'cover-image.jpg', { type: 'image/jpeg' })
        const dataTransfer = new DataTransfer()
        dataTransfer.items.add(file)
        this.inputTarget.files = dataTransfer.files
      })
  }

  updatePreview(imageUrl) {
    const container = this.element.querySelector('.text-center')

    // Replace drop zone with preview
    container.innerHTML = `
      <img src="${imageUrl}" class="mx-auto rounded-lg shadow-md mb-4 max-h-48 object-cover" data-image-upload-target="preview" alt="Cover image preview">
      <button type="button" data-action="click->image-upload#removeImage" class="text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300 text-sm font-medium">
        Remove Image
      </button>
    `
  }

  removeImage() {
    const container = this.element.querySelector('.text-center')

    // Clear the file input
    this.inputTarget.value = ''

    // Restore drop zone
    container.innerHTML = `
      <div data-image-upload-target="dropZone">
        <svg class="w-12 h-12 text-gray-400 dark:text-gray-500 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
        </svg>
        <p class="text-gray-600 dark:text-gray-400 mb-2">Choose a cover image for your wishlist</p>
        <button type="button" data-action="click->image-upload#openFileDialog" class="bg-rose-500 hover:bg-rose-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition duration-200">
          Choose Image
        </button>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-2">Recommended: 800x400px, JPG or PNG</p>
      </div>
    `

    // Re-setup drop zone
    this.setupDropZone()
  }
}