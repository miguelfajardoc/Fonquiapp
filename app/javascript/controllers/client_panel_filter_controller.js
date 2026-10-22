import { Controller } from "@hotwired/stimulus"

// Reloads a panel's Turbo Frame scoped to the chosen record (e.g. a client's
// pending products or a route's default quantities below a create form)
// whenever that choice changes. The frame's src is the current page's own URL
// with the chosen id swapped in, so Turbo extracts the matching frame from
// that page's fresh render. The query key defaults to "client_id" and can be
// changed with the `param` value. The id comes from a combobox event's detail
// or, for a plain select's change event, from the select itself. Events
// without a selected value (a combobox removal) and the `clear` action (e.g. a
// zone select change that clears the choice) remove the key, which returns
// the panel to its choose-a-record prompt.
export default class extends Controller {
  static targets = ["frame"]
  static values = { param: { type: String, default: "client_id" } }

  reload(event) {
    const value = event.type === "change" ? event.target.value : event.detail?.value
    this.load(value)
  }

  clear() {
    this.load(null)
  }

  load(value) {
    const url = new URL(window.location.href)
    if (value) {
      url.searchParams.set(this.paramValue, value)
    } else {
      url.searchParams.delete(this.paramValue)
    }
    this.frameTarget.src = url.toString()
  }
}
