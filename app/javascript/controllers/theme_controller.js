import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"

export default class extends Controller {
  static values = { 
    current: String,
    authenticated: Boolean 
  }
  
  static targets = ["toggle", "icon", "text"]
  
  connect() {
    this.applyTheme()
    this.watchSystemPreference()
    this.updateToggleUI()
  }
  
  toggle() {
    const themes = ['light', 'dark', 'system']
    const currentIndex = themes.indexOf(this.currentValue)
    const nextIndex = (currentIndex + 1) % themes.length
    const newTheme = themes[nextIndex]
    
    this.currentValue = newTheme
    this.applyTheme()
    this.savePreference()
    this.updateToggleUI()
  }
  
  applyTheme() {
    const html = document.documentElement
    html.classList.remove('dark')
    
    const shouldBeDark = this.currentValue === 'dark' || 
        (this.currentValue === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)
    
    if (shouldBeDark) {
      html.classList.add('dark')
    }
  }
  
  savePreference() {
    // Save to localStorage for immediate effect
    localStorage.setItem('theme', this.currentValue)
    
    // Save to database if authenticated
    if (this.authenticatedValue) {
      fetch('/theme', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ theme_preference: this.currentValue })
      }).then(response => {
        if (!response.ok) {
          console.error('Failed to save theme preference')
        }
      }).catch(error => {
        console.error('Error saving theme preference:', error)
      })
    }
  }
  
  updateToggleUI() {
    if (!this.hasIconTarget || !this.hasTextTarget) return
    
    // For system preference, show the actual resolved theme
    let displayTheme = this.currentValue
    if (this.currentValue === 'system') {
      displayTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
    }
    
    const icons = {
      light: '☀️',
      dark: '🌙'
    }
    
    const labels = {
      light: document.documentElement.lang === 'pt-BR' ? 'Modo claro' : 'Light mode',
      dark: document.documentElement.lang === 'pt-BR' ? 'Modo escuro' : 'Dark mode'
    }
    
    this.iconTarget.textContent = icons[displayTheme]
    this.textTarget.textContent = labels[displayTheme]
  }
  
  watchSystemPreference() {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    mediaQuery.addListener(() => {
      if (this.currentValue === 'system') {
        this.applyTheme()
        this.updateToggleUI() // Update UI to show the new resolved theme
      }
    })
  }
}