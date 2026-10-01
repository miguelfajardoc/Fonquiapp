import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Drives the route form's client-stop editor: adding, removing, and
// drag-reordering rows entirely client-side. Every row's hidden position
// input is recomputed from DOM order after any change, so the submitted
// route_stops_attributes always match what's on screen, with no server
// round-trip until the form is actually submitted. Changing the zone
// reloads the row template's client options and clears every row already
// added, since a route's stops must belong to its own zone.
export default class extends Controller {
  static targets = ["list", "template", "row"]
  static values = { clientOptionsUrl: String }

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      handle: "[data-role='drag-handle']",
      onEnd: () => this.recomputePositions()
    })
    this.recomputePositions()
    this.disableChosenClients()
  }

  disconnect() {
    this.sortable?.destroy()
  }

  async zoneChanged(event) {
    const zoneId = event.target.value
    const html = zoneId ? await (await fetch(`${this.clientOptionsUrlValue}?zone_id=${zoneId}`)).text() : ""

    this.templateTarget.content.querySelector("[data-role='client-select']").innerHTML = html
    this.clearRows()
  }

  addRow() {
    const row = this.templateTarget.content.firstElementChild.cloneNode(true)
    this.listTarget.appendChild(row)
    this.recomputePositions()
    this.disableChosenClients()
  }

  removeRow(event) {
    const row = event.target.closest("[data-route-stops-target='row']")
    const destroyInput = row.querySelector("[data-role='destroy-input']")

    if (destroyInput.dataset.persisted === "true") {
      destroyInput.value = "1"
      row.hidden = true
    } else {
      row.remove()
    }

    this.recomputePositions()
    this.disableChosenClients()
  }

  clientChanged() {
    this.disableChosenClients()
  }

  clearRows() {
    this.rowTargets.forEach((row) => row.remove())
  }

  recomputePositions() {
    this.visibleRows().forEach((row, index) => {
      row.querySelector("[data-role='position-input']").value = index + 1
    })
  }

  disableChosenClients() {
    const rows = this.visibleRows()
    const selects = rows.map((row) => row.querySelector("[data-role='client-select']"))
    const chosen = selects.map((select) => select.value)

    selects.forEach((select) => {
      Array.from(select.options).forEach((option) => {
        if (!option.value) return
        option.disabled = option.value !== select.value && chosen.includes(option.value)
      })
    })
  }

  visibleRows() {
    return this.rowTargets.filter((row) => !row.hidden)
  }
}
