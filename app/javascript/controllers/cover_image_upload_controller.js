import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    console.log('Cover image upload controller connected')
    this.setupNativeBridge()

    // Create hidden file input if it doesn't exist
    if (!this.hasInputTarget) {
      this.createFileInput()
    }
  }

  setupNativeBridge() {
    // Setup native mobile camera integration
    if (window.NativeBridge) {
      this.nativeBridge = window.NativeBridge
    }
  }

  createFileInput() {
    // Don't create if it already exists
    if (document.querySelector('input[name="user[cover_image]"]')) {
      return
    }

    const input = document.createElement('input')
    input.type = 'file'
    input.accept = 'image/*'
    input.name = 'user[cover_image]'
    input.className = 'hidden'
    input.setAttribute('data-cover-image-upload-target', 'input')
    input.setAttribute('data-action', 'change->cover-image-upload#previewImage')

    // Append to the form
    const form = document.getElementById('profile-form')
    if (form) {
      form.appendChild(input)
    } else {
      this.element.appendChild(input)
    }
  }

  openCamera() {
    // Try native camera first (mobile apps)
    if (this.nativeBridge && this.nativeBridge.camera) {
      this.nativeBridge.camera.takePicture({
        quality: 0.8,
        maxWidth: 1200,
        maxHeight: 400,
        allowEdit: true
      }).then(result => {
        if (result.success && result.imageData) {
          this.processImageData(result.imageData)
        }
      }).catch(error => {
        console.error('Native camera error:', error)
        // Fallback to file input
        this.openFileDialog()
      })
    } else {
      this.openFileDialog()
    }
  }

  openFileDialog() {
    if (this.hasInputTarget) {
      this.inputTarget.click()
    } else {
      // Try to find the input by name
      const input = document.querySelector('input[name="user[cover_image]"]')
      if (input) {
        input.click()
      }
    }
  }

  previewImage(event) {
    console.log('Cover image preview triggered', event)
    const file = event.target.files[0]
    console.log('Selected file:', file)
    if (file) {
      this.processFile(file)
    }
  }

  previewAndSubmit(event) {
    console.log('Cover image preview and submit triggered', event)
    const file = event.target.files[0]
    console.log('Selected file:', file)
    if (file) {
      this.processFile(file)
      // Auto-submit the form after a short delay to allow preview to render
      setTimeout(() => {
        console.log('Auto-submitting form')
        const form = event.target.closest('form')
        if (form) {
          form.submit()
        }
      }, 500)
    }
  }

  processFile(file) {
    // Validate file type
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      return
    }

    // Validate file size (max 10MB for cover images)
    if (file.size > 10 * 1024 * 1024) {
      alert('Image file size must be less than 10MB')
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.updateCoverPreview(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  processImageData(imageData) {
    // For native mobile integration
    this.updateCoverPreview(imageData)

    // Convert base64 to blob and set to input for form submission
    fetch(imageData)
      .then(response => response.blob())
      .then(blob => {
        const file = new File([blob], 'cover-image.jpg', { type: 'image/jpeg' })
        const dataTransfer = new DataTransfer()
        dataTransfer.items.add(file)

        const input = this.hasInputTarget ? this.inputTarget : document.querySelector('input[name="user[cover_image]"]')
        if (input) {
          input.files = dataTransfer.files
        }
      })
  }

  updateCoverPreview(imageUrl) {
    console.log('Updating cover preview with:', imageUrl)

    // Find the cover image container
    const coverContainer = document.querySelector('.h-48.md\\:h-64')
    console.log('Found cover container:', coverContainer)

    if (coverContainer) {
      // Remove existing image
      const existingImg = coverContainer.querySelector('img')
      if (existingImg) {
        console.log('Removing existing image')
        existingImg.remove()
      }

      // Create new image element
      const newImg = document.createElement('img')
      newImg.src = imageUrl
      newImg.alt = 'Cover image preview'
      newImg.className = 'absolute inset-0 w-full h-full object-cover'
      console.log('Created new image element:', newImg)

      // Insert before the overlay div
      const overlay = coverContainer.querySelector('.absolute.inset-0.bg-black\\/20')
      if (overlay) {
        coverContainer.insertBefore(newImg, overlay)
        console.log('Inserted image before overlay')
      } else {
        coverContainer.appendChild(newImg)
        console.log('Appended image to container')
      }

      // Update the background class to show we have an image
      const oldClassName = coverContainer.className
      coverContainer.className = coverContainer.className.replace(
        /bg-gradient-to-r from-rose-400 via-purple-500 to-indigo-500/,
        'bg-gray-800'
      )
      console.log('Updated container class from:', oldClassName, 'to:', coverContainer.className)

      // Trigger form tracker to show unsaved changes
      const formTracker = document.querySelector('[data-controller*="form-tracker"]')
      if (formTracker) {
        const event = new Event('input', { bubbles: true })
        formTracker.dispatchEvent(event)
        console.log('Triggered form tracker for unsaved changes')
      }
    }
  }
}