import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = {
    default: String,
    persist: { type: Boolean, default: false }
  }

  connect() {
    if (this.persistValue) {
      const savedTab = localStorage.getItem(`profile-tab-${this.element.dataset.userId}`)
      if (savedTab && this.hasTabTarget) {
        const savedTabElement = this.tabTargets.find(tab => tab.dataset.tab === savedTab)
        if (savedTabElement) {
          this.switchTo(savedTabElement)
          return
        }
      }
    }

    if (this.defaultValue) {
      const defaultTab = this.tabTargets.find(tab => tab.dataset.tab === this.defaultValue)
      if (defaultTab) {
        this.switchTo(defaultTab)
      }
    } else if (this.hasTabTarget) {
      this.switchTo(this.tabTargets[0])
    }
  }

  switch(event) {
    event.preventDefault()
    this.switchTo(event.currentTarget)
  }

  switchTo(tabElement) {
    const tabName = tabElement.dataset.tab

    // Update tab states
    this.tabTargets.forEach(tab => {
      if (tab === tabElement) {
        tab.classList.add("border-rose-500", "text-rose-600", "dark:text-rose-400")
        tab.classList.remove("border-transparent", "text-gray-500", "dark:text-gray-400", "hover:text-gray-700", "hover:border-gray-300", "dark:hover:text-gray-300")
        tab.setAttribute("aria-selected", "true")
      } else {
        tab.classList.remove("border-rose-500", "text-rose-600", "dark:text-rose-400")
        tab.classList.add("border-transparent", "text-gray-500", "dark:text-gray-400", "hover:text-gray-700", "hover:border-gray-300", "dark:hover:text-gray-300")
        tab.setAttribute("aria-selected", "false")
      }
    })

    // Update panel visibility
    this.panelTargets.forEach(panel => {
      if (panel.dataset.panel === tabName) {
        panel.classList.remove("hidden")
        panel.setAttribute("aria-hidden", "false")
      } else {
        panel.classList.add("hidden")
        panel.setAttribute("aria-hidden", "true")
      }
    })

    // Save to localStorage if persist is enabled
    if (this.persistValue) {
      localStorage.setItem(`profile-tab-${this.element.dataset.userId}`, tabName)
    }

    // Update URL without reload (optional)
    const url = new URL(window.location)
    url.searchParams.set('tab', tabName)
    window.history.replaceState({}, '', url)
  }
}