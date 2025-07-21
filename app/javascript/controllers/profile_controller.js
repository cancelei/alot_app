// Profile page controller for user profile management
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatarPreview", "passwordFields", "walletSection"]

  connect() {
    // Initialize any profile page elements
    this.togglePasswordFields(false)
  }

  // Preview avatar image before upload
  previewAvatar(event) {
    const input = event.target
    if (input.files && input.files[0]) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.avatarPreviewTarget.src = e.target.result
        this.avatarPreviewTarget.classList.remove("hidden")
      }
      reader.readAsDataURL(input.files[0])
    }
  }

  // Toggle password change fields visibility
  togglePasswordFields(event) {
    if (event) {
      event.preventDefault()
    }
    
    const showFields = event ? !this.passwordFieldsTarget.classList.contains("hidden") : false
    
    if (showFields) {
      this.passwordFieldsTarget.classList.add("hidden")
    } else {
      this.passwordFieldsTarget.classList.remove("hidden")
    }
  }

  // Toggle wallet connection section
  toggleWalletSection(event) {
    if (event) {
      event.preventDefault()
    }
    
    this.walletSectionTarget.classList.toggle("hidden")
  }
}
