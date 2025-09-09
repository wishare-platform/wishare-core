import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateField"]

  toggleDateField() {
    const selectedValue = this.element.value
    const dateField = this.dateFieldTarget

    if (selectedValue === "none" || selectedValue === "") {
      dateField.classList.add("hidden")
    } else {
      dateField.classList.remove("hidden")
    }
  }
}