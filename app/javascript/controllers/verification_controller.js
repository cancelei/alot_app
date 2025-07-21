import { Controller } from "@hotwired/stimulus"

/**
 * Verification Controller
 * 
 * This controller handles the verification UI interactions for lottery results and bet transactions
 * It provides interactive verification steps, animations, and copy-to-clipboard functionality
 */
export default class extends Controller {
  static targets = [
    "step", 
    "details", 
    "copyButton", 
    "copyText", 
    "verificationStatus",
    "verificationResult"
  ]
  
  static values = {
    currentStep: Number,
    totalSteps: Number,
    transactionHash: String,
    verificationUrl: String
  }
  
  connect() {
    // Initialize with first step active
    this.currentStepValue = 0
    this.showCurrentStep()
    
    // If verification is complete, show the result
    if (this.hasVerificationResultTarget) {
      this.animateVerificationResult()
    }
  }
  
  nextStep() {
    if (this.currentStepValue < this.totalStepsValue - 1) {
      this.currentStepValue++
      this.showCurrentStep()
    }
  }
  
  previousStep() {
    if (this.currentStepValue > 0) {
      this.currentStepValue--
      this.showCurrentStep()
    }
  }
  
  showCurrentStep() {
    // Hide all steps
    this.stepTargets.forEach((step, index) => {
      step.classList.add('hidden')
      
      // Update step indicators
      const indicator = document.getElementById(`step-indicator-${index}`)
      if (indicator) {
        if (index < this.currentStepValue) {
          // Completed step
          indicator.classList.remove('bg-gray-200', 'border-gray-300', 'bg-blue-100', 'border-blue-500')
          indicator.classList.add('bg-green-100', 'border-green-500')
        } else if (index === this.currentStepValue) {
          // Current step
          indicator.classList.remove('bg-gray-200', 'border-gray-300', 'bg-green-100', 'border-green-500')
          indicator.classList.add('bg-blue-100', 'border-blue-500')
        } else {
          // Future step
          indicator.classList.remove('bg-green-100', 'border-green-500', 'bg-blue-100', 'border-blue-500')
          indicator.classList.add('bg-gray-200', 'border-gray-300')
        }
      }
    })
    
    // Show current step
    if (this.stepTargets[this.currentStepValue]) {
      this.stepTargets[this.currentStepValue].classList.remove('hidden')
      
      // Animate the step entrance
      this.animateStepEntrance(this.stepTargets[this.currentStepValue])
    }
    
    // Update navigation buttons state
    this.updateNavigationState()
  }
  
  updateNavigationState() {
    const prevButton = document.getElementById('prev-step-button')
    const nextButton = document.getElementById('next-step-button')
    
    if (prevButton) {
      if (this.currentStepValue === 0) {
        prevButton.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        prevButton.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
    
    if (nextButton) {
      if (this.currentStepValue === this.totalStepsValue - 1) {
        nextButton.classList.add('opacity-50', 'cursor-not-allowed')
      } else {
        nextButton.classList.remove('opacity-50', 'cursor-not-allowed')
      }
    }
  }
  
  toggleDetails(event) {
    const detailsId = event.currentTarget.dataset.detailsId
    const detailsElement = document.getElementById(detailsId)
    
    if (detailsElement) {
      if (detailsElement.classList.contains('hidden')) {
        // Show details with animation
        detailsElement.classList.remove('hidden')
        detailsElement.classList.add('animate__animated', 'animate__fadeIn')
        
        // Update button text
        event.currentTarget.textContent = 'Hide Details'
      } else {
        // Hide details with animation
        detailsElement.classList.add('animate__animated', 'animate__fadeOut')
        
        // Wait for animation to complete before hiding
        setTimeout(() => {
          detailsElement.classList.add('hidden')
          detailsElement.classList.remove('animate__animated', 'animate__fadeOut')
        }, 500)
        
        // Update button text
        event.currentTarget.textContent = 'Show Details'
      }
    }
  }
  
  copyToClipboard(event) {
    const textToCopy = this.copyTextTarget.textContent
    
    navigator.clipboard.writeText(textToCopy).then(() => {
      // Show success message
      const button = event.currentTarget
      const originalText = button.textContent
      
      button.textContent = 'Copied!'
      button.classList.remove('bg-blue-600', 'hover:bg-blue-700')
      button.classList.add('bg-green-600', 'hover:bg-green-700')
      
      // Reset button after 2 seconds
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove('bg-green-600', 'hover:bg-green-700')
        button.classList.add('bg-blue-600', 'hover:bg-blue-700')
      }, 2000)
    })
  }
  
  animateStepEntrance(element) {
    element.classList.add('animate__animated', 'animate__fadeIn')
    
    // Remove animation classes after animation completes
    setTimeout(() => {
      element.classList.remove('animate__animated', 'animate__fadeIn')
    }, 1000)
  }
  
  animateVerificationResult() {
    if (this.verificationResultTarget) {
      this.verificationResultTarget.classList.add('animate__animated', 'animate__bounceIn')
      
      // Remove animation classes after animation completes
      setTimeout(() => {
        this.verificationResultTarget.classList.remove('animate__animated', 'animate__bounceIn')
      }, 1000)
    }
  }
  
  verifyOnBlockchain() {
    // In MVP, show a message explaining that this would verify on blockchain in Phase 2
    if (this.hasVerificationStatusTarget) {
      this.verificationStatusTarget.textContent = 'Simulating blockchain verification...'
      this.verificationStatusTarget.classList.remove('hidden')
      
      // Simulate verification delay
      setTimeout(() => {
        this.verificationStatusTarget.textContent = 'Verification successful! This is a simulated result for the MVP.'
        this.verificationStatusTarget.classList.remove('text-yellow-600')
        this.verificationStatusTarget.classList.add('text-green-600')
      }, 2000)
    }
  }
}
