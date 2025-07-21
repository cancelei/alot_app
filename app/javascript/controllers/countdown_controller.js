import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="countdown"
export default class extends Controller {
  static targets = ["display"]
  static values = {
    end: Number
  }

  connect() {
    this.updateCountdown()
    this.interval = setInterval(() => {
      this.updateCountdown()
    }, 1000)
  }

  disconnect() {
    if (this.interval) {
      clearInterval(this.interval)
    }
  }

  updateCountdown() {
    const now = Math.floor(Date.now() / 1000)
    const timeLeft = this.endValue - now
    
    if (timeLeft <= 0) {
      this.displayTarget.textContent = "Ended"
      clearInterval(this.interval)
      return
    }
    
    const days = Math.floor(timeLeft / 86400)
    const hours = Math.floor((timeLeft % 86400) / 3600)
    const minutes = Math.floor((timeLeft % 3600) / 60)
    const seconds = Math.floor(timeLeft % 60)
    
    if (days > 0) {
      this.displayTarget.textContent = `${days}d ${hours}h ${minutes}m`
    } else {
      this.displayTarget.textContent = `${hours}h ${minutes}m ${seconds}s`
    }
  }
}
