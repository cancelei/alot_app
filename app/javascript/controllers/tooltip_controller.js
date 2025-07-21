import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tooltip"
export default class extends Controller {
  static values = {
    content: String,
    position: { type: String, default: 'top' }
  }
  
  static targets = ["tooltip"]
  
  connect() {
    // Create tooltip element if it doesn't exist
    if (!this.hasTooltipTarget) {
      this.createTooltipElement()
    }
    
    // Hide tooltip initially
    this.hideTooltip()
  }
  
  // Create the tooltip element
  createTooltipElement() {
    const tooltip = document.createElement('div')
    tooltip.classList.add(
      'absolute', 'hidden', 'bg-gray-800', 'text-white', 'text-xs',
      'rounded', 'p-2', 'z-50', 'max-w-xs', 'shadow-lg'
    )
    tooltip.setAttribute('data-tooltip-target', 'tooltip')
    this.element.appendChild(tooltip)
  }
  
  // Show tooltip on mouseenter
  mouseEnter() {
    this.tooltipTarget.textContent = this.contentValue
    this.tooltipTarget.classList.remove('hidden')
    this.positionTooltip()
  }
  
  // Hide tooltip on mouseleave
  mouseLeave() {
    this.hideTooltip()
  }
  
  // Position the tooltip based on the position value
  positionTooltip() {
    const elementRect = this.element.getBoundingClientRect()
    const tooltipRect = this.tooltipTarget.getBoundingClientRect()
    
    // Reset any previous positioning
    this.tooltipTarget.style.top = ''
    this.tooltipTarget.style.bottom = ''
    this.tooltipTarget.style.left = ''
    this.tooltipTarget.style.right = ''
    
    switch (this.positionValue) {
      case 'top':
        this.tooltipTarget.style.bottom = `${elementRect.height + 5}px`
        this.tooltipTarget.style.left = `${(elementRect.width - tooltipRect.width) / 2}px`
        break
      case 'bottom':
        this.tooltipTarget.style.top = `${elementRect.height + 5}px`
        this.tooltipTarget.style.left = `${(elementRect.width - tooltipRect.width) / 2}px`
        break
      case 'left':
        this.tooltipTarget.style.right = `${elementRect.width + 5}px`
        this.tooltipTarget.style.top = `${(elementRect.height - tooltipRect.height) / 2}px`
        break
      case 'right':
        this.tooltipTarget.style.left = `${elementRect.width + 5}px`
        this.tooltipTarget.style.top = `${(elementRect.height - tooltipRect.height) / 2}px`
        break
    }
  }
  
  // Hide the tooltip
  hideTooltip() {
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.add('hidden')
    }
  }
}
