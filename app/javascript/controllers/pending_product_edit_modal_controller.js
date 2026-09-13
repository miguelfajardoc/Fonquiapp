import { Controller } from "@hotwired/stimulus"

// Drives a single edit-form <dialog> shared by every row on the page.
// "open" points the inner Turbo Frame at the record's edit URL and shows
// the dialog; the frame's own response (rendered by PendingProductsController)
// fills it in. A successful submit inside the frame closes the dialog —
// the row itself is updated separately, by that same response's turbo_stream.
export default class extends Controller {
  static targets = ["dialog", "frame"]

  open({ params: { url } }) {
    this.frameTarget.src = url
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  submitEnd(event) {
    if (event.detail.success) this.dialogTarget.close()
  }
}
