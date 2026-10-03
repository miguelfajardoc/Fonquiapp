import { Controller } from "@hotwired/stimulus"

// Reloads a client-scoped panel's Turbo Frame (e.g. the client's pending
// products or default quantities below a create form) whenever the client
// choice changes. The frame's src is the current page's own URL with
// client_id swapped in, so Turbo extracts the matching frame from that page's
// fresh render. Events without a selected value (a combobox removal, or a
// zone select change that clears the client) remove client_id, which returns
// the panel to its choose-a-client prompt.
export default class extends Controller {
  static targets = ["frame"]

  reload(event) {
    const url = new URL(window.location.href)
    const clientId = event.detail?.value
    if (clientId) {
      url.searchParams.set("client_id", clientId)
    } else {
      url.searchParams.delete("client_id")
    }
    this.frameTarget.src = url.toString()
  }
}
