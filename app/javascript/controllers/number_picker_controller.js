import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["number", "selectedNumbers", "totalCost", "odds", "purchaseButton"]
  static values = { 
    maxNumbers: Number, 
    minNumbers: Number, 
    baseCost: Number,
    maxRange: Number,
    lotteryId: Number
  }

  connect() {
    this.selectedNumbers = new Set()
    this.updateDisplay()
    this.updatePurchaseButton()
  }

  selectNumber(event) {
    const numberElement = event.currentTarget
    const number = parseInt(numberElement.dataset.number)
    
    if (this.selectedNumbers.has(number)) {
      // Deselect number
      this.selectedNumbers.delete(number)
      numberElement.classList.remove("selected", "bg-blue-600", "text-white")
      numberElement.classList.add("bg-white", "text-gray-900", "hover:bg-gray-50")
    } else {
      // Check if we can select more numbers
      if (this.selectedNumbers.size >= this.maxNumbersValue) {
        this.showMessage(`You can only select up to ${this.maxNumbersValue} numbers`, 'warning')
        return
      }
      
      // Select number
      this.selectedNumbers.add(number)
      numberElement.classList.remove("bg-white", "text-gray-900", "hover:bg-gray-50")
      numberElement.classList.add("selected", "bg-blue-600", "text-white")
    }
    
    this.updateDisplay()
    this.updatePurchaseButton()
  }

  quickPick() {
    // Clear current selection
    this.clearSelection()
    
    // Generate random numbers
    const availableNumbers = Array.from({length: this.maxRangeValue}, (_, i) => i + 1)
    const selectedCount = this.minNumbersValue || Math.floor(this.maxNumbersValue / 2)
    
    for (let i = 0; i < selectedCount; i++) {
      const randomIndex = Math.floor(Math.random() * availableNumbers.length)
      const number = availableNumbers.splice(randomIndex, 1)[0]
      this.selectedNumbers.add(number)
      
      // Update UI
      const numberElement = this.numberTargets.find(el => 
        parseInt(el.dataset.number) === number
      )
      if (numberElement) {
        numberElement.classList.remove("bg-white", "text-gray-900", "hover:bg-gray-50")
        numberElement.classList.add("selected", "bg-blue-600", "text-white")
      }
    }
    
    this.updateDisplay()
    this.updatePurchaseButton()
    this.showMessage(`Quick Pick selected ${selectedCount} numbers for you!`, 'success')
  }

  clearSelection() {
    this.selectedNumbers.clear()
    this.numberTargets.forEach(element => {
      element.classList.remove("selected", "bg-blue-600", "text-white")
      element.classList.add("bg-white", "text-gray-900", "hover:bg-gray-50")
    })
    this.updateDisplay()
    this.updatePurchaseButton()
  }

  updateDisplay() {
    // Update selected numbers display
    const sortedNumbers = Array.from(this.selectedNumbers).sort((a, b) => a - b)
    if (this.hasSelectedNumbersTarget) {
      this.selectedNumbersTarget.textContent = sortedNumbers.length > 0 
        ? sortedNumbers.join(', ') 
        : 'No numbers selected'
    }
    
    // Update total cost
    const totalCost = this.calculateTotalCost()
    if (this.hasTotalCostTarget) {
      this.totalCostTarget.textContent = `$${totalCost.toFixed(2)}`
    }
    
    // Update odds display
    const odds = this.calculateOdds()
    if (this.hasOddsTarget) {
      this.oddsTarget.textContent = odds
    }
  }

  calculateTotalCost() {
    const numSelected = this.selectedNumbers.size
    if (numSelected === 0) return 0
    
    // Base cost multiplied by complexity factor
    // More numbers = higher cost but better odds
    const complexityMultiplier = Math.pow(1.5, numSelected - (this.minNumbersValue || 1))
    return this.baseCostValue * complexityMultiplier
  }

  calculateOdds() {
    const numSelected = this.selectedNumbers.size
    if (numSelected === 0) return "Select numbers to see odds"
    
    // Simple odds calculation (can be made more sophisticated)
    const totalCombinations = this.combination(this.maxRangeValue, numSelected)
    return `1 in ${totalCombinations.toLocaleString()}`
  }

  combination(n, r) {
    if (r > n) return 0
    if (r === 0 || r === n) return 1
    
    let result = 1
    for (let i = 0; i < r; i++) {
      result = result * (n - i) / (i + 1)
    }
    return Math.round(result)
  }

  updatePurchaseButton() {
    if (!this.hasPurchaseButtonTarget) return
    
    const numSelected = this.selectedNumbers.size
    const minRequired = this.minNumbersValue || 1
    
    if (numSelected >= minRequired) {
      this.purchaseButtonTarget.disabled = false
      this.purchaseButtonTarget.classList.remove("bg-gray-400", "cursor-not-allowed")
      this.purchaseButtonTarget.classList.add("bg-blue-600", "hover:bg-blue-700")
      this.purchaseButtonTarget.textContent = `Purchase Ticket - $${this.calculateTotalCost().toFixed(2)}`
    } else {
      this.purchaseButtonTarget.disabled = true
      this.purchaseButtonTarget.classList.remove("bg-blue-600", "hover:bg-blue-700")
      this.purchaseButtonTarget.classList.add("bg-gray-400", "cursor-not-allowed")
      this.purchaseButtonTarget.textContent = `Select ${minRequired - numSelected} more number${minRequired - numSelected > 1 ? 's' : ''}`
    }
  }

  purchaseTicket() {
    if (this.selectedNumbers.size < (this.minNumbersValue || 1)) {
      this.showMessage('Please select the required number of numbers', 'error')
      return
    }

    const selectedArray = Array.from(this.selectedNumbers).sort((a, b) => a - b)
    const totalCost = this.calculateTotalCost()
    
    // Show confirmation modal
    if (confirm(`Purchase lottery ticket with numbers: ${selectedArray.join(', ')}\nTotal cost: $${totalCost.toFixed(2)}\n\nProceed with purchase?`)) {
      // Submit the form with selected numbers
      this.submitPurchase(selectedArray, totalCost)
    }
  }

  submitPurchase(numbers, cost) {
    // Create a form and submit it
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = `/lottery_games/${this.lotteryIdValue}/tickets`
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }
    
    // Add selected numbers
    const numbersInput = document.createElement('input')
    numbersInput.type = 'hidden'
    numbersInput.name = 'ticket[numbers]'
    numbersInput.value = JSON.stringify(numbers)
    form.appendChild(numbersInput)
    
    // Add cost
    const costInput = document.createElement('input')
    costInput.type = 'hidden'
    costInput.name = 'ticket[cost]'
    costInput.value = cost.toFixed(2)
    form.appendChild(costInput)
    
    document.body.appendChild(form)
    form.submit()
  }

  showMessage(message, type = 'info') {
    // Create a temporary message element
    const messageDiv = document.createElement('div')
    messageDiv.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg z-50 ${
      type === 'success' ? 'bg-green-100 text-green-800 border border-green-200' :
      type === 'warning' ? 'bg-yellow-100 text-yellow-800 border border-yellow-200' :
      type === 'error' ? 'bg-red-100 text-red-800 border border-red-200' :
      'bg-blue-100 text-blue-800 border border-blue-200'
    }`
    messageDiv.textContent = message
    
    document.body.appendChild(messageDiv)
    
    // Remove after 3 seconds
    setTimeout(() => {
      if (messageDiv.parentNode) {
        messageDiv.parentNode.removeChild(messageDiv)
      }
    }, 3000)
  }
}
