import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container", "background"]
  
  connect() {
    // Initialize modal in closed state
    this.close()
    
    // Add event listener for escape key
    document.addEventListener("keydown", this.handleKeydown.bind(this))
  }
  
  disconnect() {
    // Remove event listener when controller is disconnected
    document.removeEventListener("keydown", this.handleKeydown.bind(this))
  }
  
  open() {
    // Show the modal
    this.containerTarget.classList.remove("hidden")
    this.backgroundTarget.classList.remove("hidden")
    
    // Add animation classes
    this.containerTarget.classList.add("transform", "ease-out", "duration-300", "transition-opacity", "opacity-100", "scale-100")
    this.backgroundTarget.classList.add("ease-out", "duration-300", "transition-opacity", "opacity-75")
    
    // Prevent body scrolling when modal is open
    document.body.classList.add("overflow-hidden")
  }
  
  close() {
    // Hide the modal
    this.containerTarget.classList.add("hidden")
    this.backgroundTarget.classList.add("hidden")
    
    // Remove animation classes
    this.containerTarget.classList.remove("transform", "ease-out", "duration-300", "transition-opacity", "opacity-100", "scale-100")
    this.backgroundTarget.classList.remove("ease-out", "duration-300", "transition-opacity", "opacity-75")
    
    // Restore body scrolling
    document.body.classList.remove("overflow-hidden")
  }
  
  handleKeydown(event) {
    // Close modal when escape key is pressed
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  // Close modal when clicking on the background
  backgroundClick(event) {
    if (event.target === this.backgroundTarget) {
      this.close()
    }
  }
}
