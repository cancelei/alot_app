import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="feature-request"
export default class extends Controller {
  static targets = ["voteCount"]
  static values = {
    id: Number,
    votes: { type: Number, default: 0 }
  }
  
  connect() {
    // Initialize vote count display
    if (this.hasVoteCountTarget) {
      this.voteCountTarget.textContent = this.votesValue
    }
  }
  
  // Upvote a feature request (simulated in MVP)
  upvote(event) {
    event.preventDefault()
    
    // In MVP, we'll just simulate the vote count
    // In Phase 2, this would make an API call to record the vote
    this.votesValue += 1
    
    if (this.hasVoteCountTarget) {
      this.voteCountTarget.textContent = this.votesValue
      
      // Add animation effect
      this.animateVoteChange(true)
    }
    
    // Disable the button temporarily to prevent spam
    const button = event.currentTarget
    button.disabled = true
    setTimeout(() => { button.disabled = false }, 1000)
  }
  
  // Downvote a feature request (simulated in MVP)
  downvote(event) {
    event.preventDefault()
    
    // In MVP, we'll just simulate the vote count
    // In Phase 2, this would make an API call to record the vote
    this.votesValue -= 1
    
    if (this.hasVoteCountTarget) {
      this.voteCountTarget.textContent = this.votesValue
      
      // Add animation effect
      this.animateVoteChange(false)
    }
    
    // Disable the button temporarily to prevent spam
    const button = event.currentTarget
    button.disabled = true
    setTimeout(() => { button.disabled = false }, 1000)
  }
  
  // Add animation effect when vote count changes
  animateVoteChange(isUpvote) {
    // Add animation class
    this.voteCountTarget.classList.add(isUpvote ? 'text-green-500' : 'text-red-500')
    this.voteCountTarget.classList.add('animate-pulse')
    
    // Remove animation class after animation completes
    setTimeout(() => {
      this.voteCountTarget.classList.remove(isUpvote ? 'text-green-500' : 'text-red-500')
      this.voteCountTarget.classList.remove('animate-pulse')
    }, 1000)
  }
}
