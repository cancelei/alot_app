// Mobile menu controller for responsive navigation
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"]

  connect() {
    // Ensure menu is closed on initial load
    this.menuTarget.classList.add("hidden")
    this.openIconTarget.classList.remove("hidden")
    this.closeIconTarget.classList.add("hidden")
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    this.openIconTarget.classList.toggle("hidden")
    this.closeIconTarget.classList.toggle("hidden")
  }
}
