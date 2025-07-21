import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="betting-form"
export default class extends Controller {
  static targets = ["amount", "submitButton", "potentialPayout", "feedback"]
  static values = {
    minBet: { type: Number, default: 1 },
    maxBet: { type: Number, default: 1000 },
    multiplier: { type: Number, default: 2 }
  }
  
  connect() {
    // Initialize form validation
    this.validateAmount()
    
    // Set initial potential payout if amount has a value
    if (this.amountTarget.value) {
      this.updatePotentialPayout()
    }
  }
  
  // Validate the bet amount in real-time
  validateAmount() {
    const amount = parseFloat(this.amountTarget.value)
    
    // Clear previous feedback
    this.clearFeedback()
    
    // Check if amount is valid
    if (isNaN(amount)) {
      this.showFeedback('Please enter a valid amount', 'error')
      this.disableSubmit()
      return false
    }
    
    // Check if amount is within allowed range
    if (amount < this.minBetValue) {
      this.showFeedback(`Minimum bet is ${this.minBetValue}`, 'error')
      this.disableSubmit()
      return false
    }
    
    if (amount > this.maxBetValue) {
      this.showFeedback(`Maximum bet is ${this.maxBetValue}`, 'error')
      this.disableSubmit()
      return false
    }
    
    // Amount is valid
    this.showFeedback('Bet amount is valid', 'success')
    this.enableSubmit()
    return true
  }
  
  // Update the potential payout display
  updatePotentialPayout() {
    if (!this.hasPotentialPayoutTarget) return
    
    const amount = parseFloat(this.amountTarget.value) || 0
    const payout = amount * this.multiplierValue
    
    this.potentialPayoutTarget.textContent = payout.toFixed(2)
  }
  
  // Handle amount input changes
  amountChanged() {
    this.validateAmount()
    this.updatePotentialPayout()
  }
  
  // Show feedback message
  showFeedback(message, type) {
    if (!this.hasFeedbackTarget) return
    
    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.remove('text-red-500', 'text-green-500')
    this.feedbackTarget.classList.add(type === 'error' ? 'text-red-500' : 'text-green-500')
    this.feedbackTarget.classList.remove('hidden')
  }
  
  // Clear feedback message
  clearFeedback() {
    if (!this.hasFeedbackTarget) return
    
    this.feedbackTarget.textContent = ''
    this.feedbackTarget.classList.add('hidden')
  }
  
  // Enable submit button
  enableSubmit() {
    if (!this.hasSubmitButtonTarget) return
    
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    this.submitButtonTarget.classList.add('hover:bg-blue-700')
  }
  
  // Disable submit button
  disableSubmit() {
    if (!this.hasSubmitButtonTarget) return
    
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    this.submitButtonTarget.classList.remove('hover:bg-blue-700')
  }
}
