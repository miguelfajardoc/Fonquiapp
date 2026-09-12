import { Controller } from "@hotwired/stimulus"

// Reloads the client combobox's Turbo Frame, scoped to the newly chosen
// zone, whenever the zone select changes. The frame's src is the current
// page's own URL (the new/edit form) with zone_id swapped in, so Turbo
// extracts the matching frame from that page's fresh render — a freshly
// rendered frame has no prior client selection, so this also clears any
// previously chosen client for free.
export default class extends Controller {
  static targets = ["frame"]

  reload(event) {
    const url = new URL(window.location.href)
    url.searchParams.set("zone_id", event.target.value)
    this.frameTarget.src = url.toString()
  }
}
