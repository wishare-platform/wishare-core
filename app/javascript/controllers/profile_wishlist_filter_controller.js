import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "container", "emptyState"]
  static values = { active: String }

  connect() {
    this.filterButtons = this.element.querySelectorAll('[data-filter]')
    this.sortSelect = this.element.querySelector('[data-action*="sort"]')
    this.updateButtonStates()
  }

  filter(event) {
    const filterType = event.currentTarget.dataset.filter
    this.activeValue = filterType
    this.updateButtonStates()
    this.filterItems()
    this.updateEmptyState()
  }

  sort(event) {
    const sortType = event.target.value
    this.sortItems(sortType)
  }

  updateButtonStates() {
    this.filterButtons.forEach(button => {
      const isActive = button.dataset.filter === this.activeValue

      if (isActive) {
        button.classList.remove('bg-gray-100', 'dark:bg-gray-700', 'text-gray-700', 'dark:text-gray-300', 'hover:bg-gray-200', 'dark:hover:bg-gray-600')
        button.classList.add('bg-rose-100', 'dark:bg-rose-900/30', 'text-rose-700', 'dark:text-rose-400')
      } else {
        button.classList.remove('bg-rose-100', 'dark:bg-rose-900/30', 'text-rose-700', 'dark:text-rose-400')
        button.classList.add('bg-gray-100', 'dark:bg-gray-700', 'text-gray-700', 'dark:text-gray-300', 'hover:bg-gray-200', 'dark:hover:bg-gray-600')
      }
    })
  }

  filterItems() {
    this.itemTargets.forEach(item => {
      const eventType = item.dataset.eventType
      let shouldShow = false

      if (this.activeValue === 'all') {
        shouldShow = true
      } else if (this.activeValue === 'none') {
        shouldShow = ['none', '', null, undefined].includes(eventType)
      } else if (this.activeValue === 'birthday') {
        shouldShow = eventType === 'birthday'
      } else if (this.activeValue === 'wedding') {
        shouldShow = eventType === 'wedding'
      } else if (this.activeValue === 'holiday') {
        shouldShow = ['christmas', 'holiday', 'valentines', 'mothers_day', 'fathers_day', 'natal'].includes(eventType)
      } else {
        // Direct match for other event types
        shouldShow = eventType === this.activeValue
      }

      if (shouldShow) {
        item.style.display = ''
        item.classList.remove('hidden')
      } else {
        item.style.display = 'none'
        item.classList.add('hidden')
      }
    })
  }

  updateEmptyState() {
    if (!this.hasEmptyStateTarget) return

    const visibleItems = this.itemTargets.filter(item => !item.classList.contains('hidden'))

    if (visibleItems.length === 0 && this.activeValue !== 'all') {
      this.emptyStateTarget.classList.remove('hidden')
      this.emptyStateTarget.style.display = ''
    } else {
      this.emptyStateTarget.classList.add('hidden')
      this.emptyStateTarget.style.display = 'none'
    }
  }

  sortItems(sortType) {
    const container = this.containerTarget
    const items = Array.from(this.itemTargets)

    items.sort((a, b) => {
      switch (sortType) {
        case 'newest':
          return parseInt(b.dataset.createdAt) - parseInt(a.dataset.createdAt)
        case 'oldest':
          return parseInt(a.dataset.createdAt) - parseInt(b.dataset.createdAt)
        case 'most_items':
          return parseInt(b.dataset.itemsCount) - parseInt(a.dataset.itemsCount)
        case 'least_items':
          return parseInt(a.dataset.itemsCount) - parseInt(b.dataset.itemsCount)
        case 'name_az':
          return a.dataset.name.localeCompare(b.dataset.name)
        case 'name_za':
          return b.dataset.name.localeCompare(a.dataset.name)
        default:
          return 0
      }
    })

    // Remove all items and re-append in sorted order
    items.forEach(item => container.removeChild(item))
    items.forEach(item => container.appendChild(item))
  }
}