import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "sortSelect", "filterButton", "noResults"]
  
  connect() {
    console.log("Wishlist items filter controller connected")
    this.currentFilter = "all"
    this.currentSort = "newest"
    this.initializeItemData()
    this.initializeButtonStates()
  }

  initializeItemData() {
    // Store original item data for sorting
    this.itemTargets.forEach(item => {
      const priceText = item.dataset.price || "0"
      // Extract numeric price value, handling different currency formats
      const priceMatch = priceText.match(/[\d,]+\.?\d*/)
      const price = priceMatch ? parseFloat(priceMatch[0].replace(/,/g, '')) : 0
      
      item.dataset.priceNumeric = price
      item.dataset.timestamp = item.dataset.createdAt || "0"
      
      // Set priority numeric values for sorting
      const priority = item.dataset.priority || "low"
      item.dataset.priorityNumeric = priority === "high" ? 3 : priority === "medium" ? 2 : 1
    })
  }

  initializeButtonStates() {
    // Set initial button states based on current filter
    this.filterButtonTargets.forEach(button => {
      if (button.dataset.filter === this.currentFilter) {
        this.setActiveButtonState(button)
      } else {
        this.setInactiveButtonState(button)
      }
    })
  }

  setActiveButtonState(button) {
    button.classList.add("bg-rose-500", "text-white", "border-rose-500")
    button.classList.remove("bg-white", "bg-gray-700", "text-gray-700", "text-gray-300", "border-gray-300", "border-gray-600")
  }

  setInactiveButtonState(button) {
    button.classList.remove("bg-rose-500", "text-white", "border-rose-500")
    button.classList.add("bg-white", "text-gray-700", "border-gray-300")
    // Let Tailwind CSS handle dark mode variants through the template classes
  }

  // Sorting functionality
  sort(event) {
    const sortBy = event ? event.target.value : this.currentSort
    this.currentSort = sortBy
    
    const items = Array.from(this.itemTargets)
    const container = items[0]?.parentNode
    
    if (!container) return
    
    // Sort items based on selected criteria
    items.sort((a, b) => {
      switch(sortBy) {
        case "newest":
          return parseInt(b.dataset.timestamp) - parseInt(a.dataset.timestamp)
        case "oldest":
          return parseInt(a.dataset.timestamp) - parseInt(b.dataset.timestamp)
        case "price_high":
          return parseFloat(b.dataset.priceNumeric) - parseFloat(a.dataset.priceNumeric)
        case "price_low":
          return parseFloat(a.dataset.priceNumeric) - parseFloat(b.dataset.priceNumeric)
        case "priority_high":
          return parseInt(b.dataset.priorityNumeric) - parseInt(a.dataset.priorityNumeric)
        case "priority_low":
          return parseInt(a.dataset.priorityNumeric) - parseInt(b.dataset.priorityNumeric)
        case "name_az":
          return a.dataset.name.localeCompare(b.dataset.name)
        case "name_za":
          return b.dataset.name.localeCompare(a.dataset.name)
        default:
          return 0
      }
    })
    
    // Reorder items in DOM
    items.forEach(item => {
      container.appendChild(item)
    })
    
    // Apply current filter after sorting
    this.applyFilter()
  }

  // Filtering functionality
  filter(event) {
    const filterType = event.currentTarget.dataset.filter
    this.currentFilter = filterType
    
    // Update active button state
    this.filterButtonTargets.forEach(button => {
      if (button.dataset.filter === filterType) {
        this.setActiveButtonState(button)
      } else {
        this.setInactiveButtonState(button)
      }
    })
    
    this.applyFilter()
  }

  applyFilter() {
    let visibleCount = 0
    
    this.itemTargets.forEach(item => {
      let shouldShow = false
      
      switch(this.currentFilter) {
        case "all":
          shouldShow = true
          break
        case "available":
          shouldShow = item.dataset.status === "available"
          break
        case "purchased":
          shouldShow = item.dataset.status === "purchased"
          break
        case "high_priority":
          shouldShow = item.dataset.priority === "high"
          break
        case "medium_priority":
          shouldShow = item.dataset.priority === "medium"
          break
        case "low_priority":
          shouldShow = item.dataset.priority === "low"
          break
        case "with_price":
          shouldShow = parseFloat(item.dataset.priceNumeric) > 0
          break
        case "no_price":
          shouldShow = parseFloat(item.dataset.priceNumeric) === 0
          break
        default:
          shouldShow = true
      }
      
      if (shouldShow) {
        item.classList.remove("hidden")
        visibleCount++
      } else {
        item.classList.add("hidden")
      }
    })
    
    // Show/hide no results message
    if (this.hasNoResultsTarget) {
      if (visibleCount === 0) {
        this.noResultsTarget.classList.remove("hidden")
      } else {
        this.noResultsTarget.classList.add("hidden")
      }
    }
    
    // Update item count if displayed
    this.updateItemCount(visibleCount)
  }

  updateItemCount(count) {
    const countElement = document.getElementById("filtered-item-count")
    if (countElement) {
      const totalCount = this.itemTargets.length
      if (this.currentFilter === "all") {
        countElement.textContent = `${totalCount} ${totalCount === 1 ? 'item' : 'items'}`
      } else {
        countElement.textContent = `${count} of ${totalCount} items`
      }
    }
  }

  // Quick filter methods
  showAll() {
    this.currentFilter = "all"
    const event = { currentTarget: { dataset: { filter: "all" } } }
    this.filter(event)
  }

  showAvailable() {
    this.currentFilter = "available"
    const event = { currentTarget: { dataset: { filter: "available" } } }
    this.filter(event)
  }

  showPurchased() {
    this.currentFilter = "purchased"
    const event = { currentTarget: { dataset: { filter: "purchased" } } }
    this.filter(event)
  }

  // Reset all filters and sorting
  reset() {
    this.currentFilter = "all"
    this.currentSort = "newest"
    
    if (this.hasSortSelectTarget) {
      this.sortSelectTarget.value = "newest"
    }
    
    this.sort()
    this.showAll()
  }
}