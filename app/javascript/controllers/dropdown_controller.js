// Dropdown controller for navigation menus
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClickHandler)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }

  // Close dropdown when clicking outside
  outsideClickHandler = (event) => {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.hide()
    }
  }
}
