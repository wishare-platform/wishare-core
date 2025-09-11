import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hiddenField"]

  connect() {
    console.log("Birthday controller connected")
    // Initialize with existing date if available
    this.updateDate()
    
    // Also set up event listeners directly
    const month = document.getElementById("birth_month")
    const day = document.getElementById("birth_day")
    const year = document.getElementById("birth_year")
    
    if (month) month.addEventListener('change', () => this.updateDate())
    if (day) day.addEventListener('change', () => this.updateDate())
    if (year) year.addEventListener('change', () => this.updateDate())
    
    // Add form submission handler to ensure date is set
    const form = this.element.closest('form')
    if (form) {
      form.addEventListener('submit', (event) => {
        console.log("Form submitting - ensuring date is set")
        this.updateDate()
        
        // Log what will be submitted
        const formData = new FormData(form)
        console.log("Form data before submission:")
        for (let [key, value] of formData.entries()) {
          if (key.includes('date') || key.includes('birth')) {
            console.log(`${key}: ${value}`)
          }
        }
      })
    }
  }

  updateDate() {
    const month = document.getElementById("birth_month")?.value
    const day = document.getElementById("birth_day")?.value  
    const year = document.getElementById("birth_year")?.value

    console.log("Updating date with:", { month, day, year })

    if (month && day && year) {
      // Create date in YYYY-MM-DD format for the hidden field
      // Convert to strings and pad with zeros
      const monthStr = String(month).padStart(2, '0')
      const dayStr = String(day).padStart(2, '0')
      const formattedDate = `${year}-${monthStr}-${dayStr}`
      
      // Find the hidden field - try multiple approaches
      let hiddenField = null
      
      // Try using the target first
      if (this.hasHiddenFieldTarget) {
        hiddenField = this.hiddenFieldTarget
        console.log("Found hidden field via target")
      } else {
        // Try finding by name attribute
        hiddenField = document.querySelector('input[name*="date_of_birth"]')
        console.log("Trying to find hidden field by name:", hiddenField)
        
        if (!hiddenField) {
          // Try finding within the form
          const form = this.element.closest('form')
          if (form) {
            hiddenField = form.querySelector('input[type="hidden"]')
            console.log("Trying to find hidden field in form:", hiddenField)
          }
        }
      }
      
      if (hiddenField) {
        hiddenField.value = formattedDate
        console.log("Setting date_of_birth hidden field to:", formattedDate)
        console.log("Hidden field element:", hiddenField)
      } else {
        console.log("No hidden field found!")
      }
    } else {
      // Clear the hidden field if incomplete
      const hiddenField = this.hasHiddenFieldTarget ? this.hiddenFieldTarget : document.querySelector('input[name*="date_of_birth"]')
      if (hiddenField) {
        hiddenField.value = ""
        console.log("Clearing date_of_birth hidden field")
      }
    }
  }
}