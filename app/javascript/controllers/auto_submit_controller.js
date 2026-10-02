import { Controller } from "@hotwired/stimulus"

// Submits its form whenever a filter changes, so filter bars need no submit
// button. Text inputs use debouncedSubmit to wait until typing pauses; selects
// use submit. An action can blank other fields first through a `clear` param
// (comma-separated field names), e.g. clearing a dependent route select when
// its zone changes so the stale value is not submitted.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  submit({ params: { clear } = {} } = {}) {
    clearTimeout(this.timeout)
    this.clearFields(clear)
    this.element.requestSubmit()
  }

  debouncedSubmit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }

  clearFields(names) {
    if (!names) return

    names.split(",").forEach((name) => {
      this.element.querySelectorAll(`[name="${name.trim()}"]`).forEach((field) => { field.value = "" })
    })
  }
}
