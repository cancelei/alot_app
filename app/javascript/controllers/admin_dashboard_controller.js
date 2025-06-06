import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-dashboard"
export default class extends Controller {
  static targets = ["statsContainer", "refreshButton"]
  static values = {
    refreshUrl: String,
    refreshInterval: { type: Number, default: 30000 } // 30 seconds by default
  }
  
  connect() {
    // Start auto-refresh timer
    this.startRefreshTimer()
  }
  
  disconnect() {
    // Clear the refresh timer when controller is disconnected
    this.stopRefreshTimer()
  }
  
  // Start the auto-refresh timer
  startRefreshTimer() {
    this.refreshTimer = setInterval(() => {
      this.refreshStats()
    }, this.refreshIntervalValue)
  }
  
  // Stop the auto-refresh timer
  stopRefreshTimer() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
  
  // Refresh dashboard statistics
  refreshStats() {
    if (!this.hasRefreshUrlValue) return
    
    // Disable refresh button during refresh
    if (this.hasRefreshButtonTarget) {
      this.refreshButtonTarget.disabled = true
      this.refreshButtonTarget.classList.add('opacity-50')
    }
    
    // Fetch updated stats using Turbo stream
    fetch(this.refreshUrlValue, {
      headers: {
        Accept: 'text/vnd.turbo-stream.html'
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
      
      // Re-enable refresh button
      if (this.hasRefreshButtonTarget) {
        this.refreshButtonTarget.disabled = false
        this.refreshButtonTarget.classList.remove('opacity-50')
      }
    })
    .catch(error => {
      console.error('Error refreshing dashboard stats:', error)
      
      // Re-enable refresh button
      if (this.hasRefreshButtonTarget) {
        this.refreshButtonTarget.disabled = false
        this.refreshButtonTarget.classList.remove('opacity-50')
      }
    })
  }
  
  // Manual refresh triggered by button
  manualRefresh(event) {
    event.preventDefault()
    this.refreshStats()
    
    // Reset the auto-refresh timer
    this.stopRefreshTimer()
    this.startRefreshTimer()
  }
}
