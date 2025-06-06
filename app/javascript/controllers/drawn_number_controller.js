import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="drawn-number"
export default class extends Controller {
  static targets = ["input", "submit", "feedback"]
  static values = {
    min: Number,
    max: Number
  }

  connect() {
    this.validateInput()
  }

  validateInput() {
    const input = this.inputTarget
    const value = parseInt(input.value)
    const submitButton = this.submitTarget
    
    // Clear previous feedback
    if (this.hasFeedbackTarget) {
      this.feedbackTarget.textContent = ""
      this.feedbackTarget.classList.remove("text-red-600", "text-green-600")
    }
    
    // If input is empty, disable submit button
    if (!input.value) {
      submitButton.disabled = true
      return
    }
    
    // Check if input is a valid number within range
    if (isNaN(value) || value < this.minValue || value > this.maxValue) {
      submitButton.disabled = true
      
      if (this.hasFeedbackTarget) {
        this.feedbackTarget.textContent = `Please enter a number between ${this.minValue} and ${this.maxValue}`
        this.feedbackTarget.classList.add("text-red-600")
      }
    } else {
      submitButton.disabled = false
      
      if (this.hasFeedbackTarget) {
        this.feedbackTarget.textContent = "Valid number"
        this.feedbackTarget.classList.add("text-green-600")
      }
    }
  }
}
