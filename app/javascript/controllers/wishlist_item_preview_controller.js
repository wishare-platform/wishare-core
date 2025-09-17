import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="wishlist-item-preview"
export default class extends Controller {

  connect() {
    console.log("🎯 Wishlist item preview controller connected!")
  }

  showPreview(event) {
    console.log("🎯 Show preview triggered!", event.currentTarget)
    console.log("🎯 Item datasets:", event.currentTarget.dataset)

    const item = event.currentTarget
    const itemName = item.dataset.itemName
    const itemPrice = item.dataset.itemPrice
    const itemDescription = item.dataset.itemDescription
    const itemImage = item.dataset.itemImage
    const itemUrl = item.dataset.itemUrl
    const itemPriority = item.dataset.itemPriority

    console.log("🎯 Item data:", { itemName, itemPrice, itemDescription })

    // Create or get global popup
    let popup = document.getElementById('wishlist-item-popup')
    if (!popup) {
      console.log("🎯 Creating new popup")
      popup = this.createGlobalPopup()
    } else {
      console.log("🎯 Using existing popup")
    }

    // Populate popup content
    const nameEl = popup.querySelector('.popup-name')
    const priceEl = popup.querySelector('.popup-price')
    const descEl = popup.querySelector('.popup-description')
    const imageEl = popup.querySelector('.popup-image')
    const priorityEl = popup.querySelector('.popup-priority')

    console.log("🎯 Found elements:", { nameEl, priceEl, descEl, imageEl, priorityEl })

    // Add null checks for all elements
    if (nameEl) nameEl.textContent = itemName || 'No name'
    if (priceEl) priceEl.textContent = itemPrice || 'Price not set'
    if (descEl) descEl.textContent = itemDescription || 'No description available'

    // Handle image
    if (imageEl) {
      if (itemImage) {
        imageEl.innerHTML = `<img src="${itemImage}" alt="${itemName}" class="w-full h-full object-cover rounded-lg">`
      } else {
        imageEl.innerHTML = `
          <div class="w-full h-full flex items-center justify-center bg-gray-100 dark:bg-gray-700 rounded-lg">
            <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7"/>
            </svg>
          </div>
        `
      }
    }

    // Handle priority badge
    if (priorityEl) {
      this.updatePriorityBadge(itemPriority, priorityEl)
    }

    // Position and show popup
    this.positionPopup(item, popup)
    popup.classList.remove('hidden')
    console.log("🎯 Popup should now be visible:", !popup.classList.contains('hidden'))
  }

  hidePreview() {
    console.log("🎯 Hide preview triggered!")
    const popup = document.getElementById('wishlist-item-popup')
    if (popup) {
      popup.classList.add('hidden')
    }
  }

  handleClick(event) {
    console.log("🎯 Click triggered!")
    // Hide the popup first
    this.hidePreview()

    // Get the path from the data attribute
    const path = event.currentTarget.dataset.itemPath
    if (path) {
      // Navigate to the item page
      window.location.href = path
    }

    // Prevent the default link behavior since we're handling it manually
    event.preventDefault()
  }

  createGlobalPopup() {
    const popup = document.createElement('div')
    popup.id = 'wishlist-item-popup'
    popup.className = 'fixed z-50 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700 p-4 w-80 hidden backdrop-blur-sm bg-white/95 dark:bg-gray-800/95'
    popup.innerHTML = `
      <div class="flex gap-4">
        <div class="popup-image w-20 h-20 rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-700 flex-shrink-0">
          <!-- Image will be inserted here -->
        </div>
        <div class="flex-1 min-w-0">
          <h4 class="popup-name font-semibold text-gray-800 dark:text-gray-100 text-sm mb-1 truncate"></h4>
          <p class="popup-price text-rose-600 dark:text-rose-400 font-medium text-sm mb-2"></p>
          <p class="popup-description text-gray-600 dark:text-gray-400 text-xs line-clamp-2"></p>
          <div class="flex items-center gap-2 mt-2">
            <span class="popup-priority px-2 py-1 rounded-full text-xs font-medium"></span>
          </div>
        </div>
      </div>
    `
    document.body.appendChild(popup)
    return popup
  }

  positionPopup(triggerElement, popup) {
    const rect = triggerElement.getBoundingClientRect()

    // Position popup above the trigger element
    const top = rect.top - 150 // Move it higher up
    const left = Math.max(10, rect.left - 140) // Center popup relative to trigger

    popup.style.position = 'fixed'
    popup.style.top = `${Math.max(10, top)}px`
    popup.style.left = `${Math.min(left, window.innerWidth - 330)}px`
    popup.style.zIndex = '50'
  }

  updatePriorityBadge(priority, priorityTarget) {
    // Add null check for priorityTarget
    if (!priorityTarget) {
      console.warn("🎯 Priority target element is null, skipping priority badge update")
      return
    }

    // Clear existing classes
    priorityTarget.className = "px-2 py-1 rounded-full text-xs font-medium"

    switch(priority) {
      case 'high':
        priorityTarget.classList.add('bg-red-100', 'dark:bg-red-900/30', 'text-red-700', 'dark:text-red-400')
        priorityTarget.textContent = 'High Priority'
        break
      case 'medium':
        priorityTarget.classList.add('bg-yellow-100', 'dark:bg-yellow-900/30', 'text-yellow-700', 'dark:text-yellow-400')
        priorityTarget.textContent = 'Medium Priority'
        break
      case 'low':
        priorityTarget.classList.add('bg-green-100', 'dark:bg-green-900/30', 'text-green-700', 'dark:text-green-400')
        priorityTarget.textContent = 'Low Priority'
        break
      default:
        priorityTarget.classList.add('bg-gray-100', 'dark:bg-gray-700', 'text-gray-700', 'dark:text-gray-300')
        priorityTarget.textContent = 'No Priority'
    }
  }
}