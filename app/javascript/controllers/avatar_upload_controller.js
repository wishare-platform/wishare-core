import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    this.setupNativeBridge()
  }

  setupNativeBridge() {
    // Setup native mobile camera integration
    if (window.NativeBridge) {
      this.nativeBridge = window.NativeBridge
    }
  }

  openCamera() {
    // Try native camera first (mobile apps)
    if (this.nativeBridge && this.nativeBridge.camera) {
      this.nativeBridge.camera.takePicture({
        quality: 0.8,
        maxWidth: 800,
        maxHeight: 800,
        allowEdit: true
      }).then(result => {
        if (result.success && result.imageData) {
          this.uploadImageData(result.imageData)
        }
      }).catch(error => {
        console.error('Native camera error:', error)
        // Fallback to file input
        this.openFileDialog()
      })
    } else {
      // Fallback to file input with camera capture
      this.inputTarget.setAttribute('capture', 'user')
      this.inputTarget.click()
    }
  }

  openFileDialog() {
    // Remove camera capture attribute for regular file selection
    this.inputTarget.removeAttribute('capture')
    this.inputTarget.click()
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.updatePreview(e.target.result)
        this.uploadImage(file)
      }
      reader.readAsDataURL(file)
    }
  }

  updatePreview(imageUrl) {
    if (this.previewTarget.tagName === 'IMG') {
      this.previewTarget.src = imageUrl
    } else {
      // Replace div with img element
      const img = document.createElement('img')
      img.src = imageUrl
      img.className = 'w-32 h-32 rounded-full object-cover mx-auto shadow-lg'
      img.alt = 'Profile picture'
      img.dataset.avatarUploadTarget = 'preview'

      this.previewTarget.parentNode.replaceChild(img, this.previewTarget)
    }
  }

  uploadImage(file) {
    const formData = new FormData()
    formData.append('avatar', file)

    const locale = document.documentElement.lang || 'en'
    fetch(`/${locale}/profile/update_avatar`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: formData
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Image uploaded successfully
        console.log('Avatar updated successfully')
        if (data.avatar_url) {
          this.updatePreview(data.avatar_url)
        }
      } else {
        console.error('Upload failed:', data.errors || data.error)
        alert('Failed to upload image. Please try again.')
      }
    })
    .catch(error => {
      console.error('Upload error:', error)
      alert('Failed to upload image. Please try again.')
    })
  }

  uploadImageData(imageData) {
    // For native mobile apps, use the API endpoint directly
    if (this.nativeBridge && this.nativeBridge.apiRequest) {
      this.nativeBridge.apiRequest({
        url: '/api/v1/profile/avatar',
        method: 'POST',
        data: {
          avatar_base64: imageData
        }
      }).then(response => {
        if (response.status === 'success') {
          this.updatePreview(imageData)
          console.log('Avatar updated via native API')
        } else {
          console.error('Native API upload failed:', response.message)
          this.fallbackUpload(imageData)
        }
      }).catch(error => {
        console.error('Native API error:', error)
        this.fallbackUpload(imageData)
      })
    } else {
      this.fallbackUpload(imageData)
    }
  }

  fallbackUpload(imageData) {
    // Convert base64 image data to blob for web upload
    fetch(imageData)
      .then(response => response.blob())
      .then(blob => {
        const file = new File([blob], 'avatar.jpg', { type: 'image/jpeg' })
        this.updatePreview(imageData)
        this.uploadImage(file)
      })
      .catch(error => {
        console.error('Error processing image data:', error)
      })
  }

  removeAvatar() {
    if (confirm('Are you sure you want to remove your profile picture?')) {
      const locale = document.documentElement.lang || 'en'
      fetch(`/${locale}/profile/remove_avatar`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.success) {
          // Replace image with default avatar placeholder
          const placeholder = document.createElement('div')
          placeholder.className = 'w-32 h-32 rounded-full bg-gray-200 dark:bg-gray-700 flex items-center justify-center mx-auto shadow-lg'
          placeholder.dataset.avatarUploadTarget = 'preview'
          placeholder.innerHTML = `
            <svg class="w-16 h-16 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
            </svg>
          `

          this.previewTarget.parentNode.replaceChild(placeholder, this.previewTarget)
        } else {
          alert('Failed to remove avatar. Please try again.')
        }
      })
      .catch(error => {
        console.error('Remove avatar error:', error)
        alert('Failed to remove avatar. Please try again.')
      })
    }
  }
}