import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hiddenField"]

  connect() {
    // Initialize with existing date if available
    this.updateDate()
  }

  updateDate() {
    const month = document.getElementById("birth_month")?.value
    const day = document.getElementById("birth_day")?.value  
    const year = document.getElementById("birth_year")?.value

    if (month && day && year) {
      // Create date in YYYY-MM-DD format for the hidden field
      const formattedDate = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`
      
      // Update the hidden field that Rails will actually process
      if (this.hasHiddenFieldTarget) {
        this.hiddenFieldTarget.value = formattedDate
      }
    } else {
      // Clear the hidden field if incomplete
      if (this.hasHiddenFieldTarget) {
        this.hiddenFieldTarget.value = ""
      }
    }
  }
}