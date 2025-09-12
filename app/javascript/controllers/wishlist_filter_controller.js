import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterButton", "wishlistCard", "emptyState"]
  static values = { activeFilter: String }

  connect() {
    this.activeFilterValue = "my-wishlists"
    this.updateDisplay()
  }

  activeFilterValueChanged() {
    this.updateDisplay()
  }

  filterBy(event) {
    const filterType = event.currentTarget.dataset.filter
    this.activeFilterValue = filterType
  }

  updateDisplay() {
    this.updateButtons()
    this.updateCards()
    this.updateEmptyStates()
  }

  updateButtons() {
    this.filterButtonTargets.forEach(button => {
      const filter = button.dataset.filter
      const isActive = filter === this.activeFilterValue
      
      if (isActive) {
        // Remove inactive classes (including dark mode variants)
        button.classList.remove(
          "bg-white", "dark:bg-gray-700", 
          "text-gray-600", "dark:text-gray-300", 
          "border-gray-200", "dark:border-gray-600", 
          "hover:bg-gray-50", "dark:hover:bg-gray-600"
        )
        // Add active classes (including dark mode variants)
        button.classList.add(
          "bg-rose-500", "dark:bg-rose-600", 
          "text-white", 
          "border-rose-500", "dark:border-rose-600", 
          "shadow-md"
        )
      } else {
        // Remove active classes (including dark mode variants)
        button.classList.remove(
          "bg-rose-500", "dark:bg-rose-600", 
          "text-white", 
          "border-rose-500", "dark:border-rose-600", 
          "shadow-md"
        )
        // Add inactive classes (including dark mode variants)
        button.classList.add(
          "bg-white", "dark:bg-gray-700", 
          "text-gray-600", "dark:text-gray-300", 
          "border-gray-200", "dark:border-gray-600", 
          "hover:bg-gray-50", "dark:hover:bg-gray-600"
        )
      }

      // Update count
      this.updateButtonCount(button, filter)
    })
  }

  updateButtonCount(button, filter) {
    const countElement = button.querySelector('.filter-count')
    if (countElement) {
      let count = 0
      
      this.wishlistCardTargets.forEach(card => {
        const cardCategories = card.dataset.categories.split(' ')
        if (filter === 'all' || cardCategories.includes(filter)) {
          count++
        }
      })
      
      countElement.textContent = `(${count})`
    }
  }

  updateCards() {
    this.wishlistCardTargets.forEach(card => {
      const cardCategories = card.dataset.categories.split(' ')
      const shouldShow = this.activeFilterValue === 'all' || cardCategories.includes(this.activeFilterValue)
      
      if (shouldShow) {
        card.classList.remove("hidden")
        card.style.display = ""
      } else {
        card.classList.add("hidden")
        card.style.display = "none"
      }
    })
  }

  updateEmptyStates() {
    this.emptyStateTargets.forEach(emptyState => {
      const emptyStateFilter = emptyState.dataset.filter
      const shouldShow = emptyStateFilter === this.activeFilterValue
      
      // Check if there are any visible cards for this filter
      const hasVisibleCards = this.wishlistCardTargets.some(card => {
        const cardCategories = card.dataset.categories.split(' ')
        const cardMatches = this.activeFilterValue === 'all' || cardCategories.includes(this.activeFilterValue)
        return cardMatches && !card.classList.contains("hidden")
      })
      
      if (shouldShow && !hasVisibleCards) {
        emptyState.classList.remove("hidden")
        emptyState.style.display = ""
      } else {
        emptyState.classList.add("hidden")
        emptyState.style.display = "none"
      }
    })
  }
}