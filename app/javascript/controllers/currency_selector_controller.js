import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "symbol", "priceInput"]

  connect() {
    this.updateSymbol()
  }

  updateSymbol() {
    const selectedOption = this.selectTarget.selectedOptions[0]
    if (selectedOption) {
      // Extract currency symbol from the option text
      const symbolMatch = selectedOption.text.match(/^([^\s]+)/)
      if (symbolMatch) {
        this.symbolTarget.textContent = symbolMatch[1]
      }
    }
  }
}