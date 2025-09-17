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
    // Show options when pencil is clicked
    this.showAvatarOptions()
  }

  showAvatarOptions() {
    const hasAvatar = this.previewTarget.tagName === 'IMG'

    // Create a simple dropdown menu
    const menu = document.createElement('div')
    menu.className = 'absolute top-0 right-0 mt-12 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-50 min-w-40'

    const options = [
      { text: '📷 Take Photo', action: () => this.openCameraCapture() },
      { text: '📁 Choose File', action: () => this.openFileDialog() }
    ]

    if (hasAvatar) {
      options.push({ text: '🗑️ Remove Photo', action: () => this.removeAvatar() })
    }

    options.forEach(option => {
      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'w-full text-left px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 text-sm first:rounded-t-lg last:rounded-b-lg transition'
      button.textContent = option.text
      button.onclick = () => {
        option.action()
        menu.remove()
      }
      menu.appendChild(button)
    })

    // Position menu relative to the avatar container
    const container = this.previewTarget.parentNode
    container.style.position = 'relative'
    container.appendChild(menu)

    // Remove menu when clicking outside
    const removeMenu = (e) => {
      if (!menu.contains(e.target)) {
        menu.remove()
        document.removeEventListener('click', removeMenu)
      }
    }

    setTimeout(() => {
      document.addEventListener('click', removeMenu)
    }, 100)
  }

  openCameraCapture() {
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
      img.className = 'w-24 h-24 rounded-full border-4 border-rose-200 dark:border-rose-800 object-cover'
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
          // Replace image with default avatar placeholder (matching current user display style)
          const placeholder = document.createElement('div')
          placeholder.className = 'w-24 h-24 rounded-full bg-gradient-to-br from-rose-400 to-purple-500 flex items-center justify-center border-4 border-rose-200 dark:border-rose-800'
          placeholder.dataset.avatarUploadTarget = 'preview'

          // Get user's first initial from the current display
          const userInitial = document.querySelector('[data-avatar-upload-target="preview"] span')?.textContent || 'U'
          placeholder.innerHTML = `<span class="text-3xl font-bold text-white">${userInitial}</span>`

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