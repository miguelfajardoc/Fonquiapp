import { Controller } from "@hotwired/stimulus"

// Reloads the client-scoped pending products panel's Turbo Frame whenever
// the client combobox's selection changes. The frame's src is the current
// page's own URL (the create form) with client_id swapped in (or removed),
// so Turbo extracts the matching frame from that page's fresh render.
export default class extends Controller {
  static targets = ["frame"]

  reload(event) {
    const url = new URL(window.location.href)
    if (event.detail.value) {
      url.searchParams.set("client_id", event.detail.value)
    } else {
      url.searchParams.delete("client_id")
    }
    this.frameTarget.src = url.toString()
  }
}
