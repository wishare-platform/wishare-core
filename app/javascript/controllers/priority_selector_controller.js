import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selected: String }

  connect() {
    // Set initial selection based on the selected value
    this.updateInitialSelection()
  }

  updateInitialSelection() {
    const selectedValue = this.selectedValue
    if (selectedValue) {
      const radioButton = this.element.querySelector(`input[value="${selectedValue}"]`)
      if (radioButton) {
        radioButton.checked = true
      }
    }
  }

  updateSelection(event) {
    // The CSS handles the visual state via peer-checked classes
    // This is just for any additional logic if needed
    const selectedValue = event.target.value
    console.log('Priority selected:', selectedValue)
  }
}