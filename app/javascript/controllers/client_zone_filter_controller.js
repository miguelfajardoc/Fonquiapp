import { Controller } from "@hotwired/stimulus"

// Reloads a zone-dependent Turbo Frame (a client combobox or a route select),
// scoped to the newly chosen zone, whenever the zone select changes. The
// frame's src is the current page's own URL with the zone param swapped in,
// so Turbo extracts the matching frame from that page's fresh render — a
// freshly rendered frame has no prior selection, so this also clears any
// previously chosen value for free. The query key defaults to "zone_id" and
// can be changed with the `param` value when a page holds two independent
// zone selects (e.g. generation controls and table filters).
export default class extends Controller {
  static targets = ["frame"]
  static values = { param: { type: String, default: "zone_id" } }

  reload(event) {
    const url = new URL(window.location.href)
    url.searchParams.set(this.paramValue, event.target.value)
    this.frameTarget.src = url.toString()
  }
}
