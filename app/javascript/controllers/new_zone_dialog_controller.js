import { Controller } from "@hotwired/stimulus"

// Drives the "create a zone without leaving this form" dialog: choosing the
// select's "Crear zona" option opens it instead of setting that as the
// value; closes on Cancelar/Esc (reverting the select to what it held
// before), and closes itself (keeping the newly selected zone) once the
// zone form it contains submits successfully — the new zone's <option> is
// inserted into the select, selected, by the server's turbo_stream response.
export default class extends Controller {
  static targets = ["dialog", "select"]

  connect() {
    this.previousValue = this.selectTarget.value
  }

  openOnNewOption() {
    if (this.selectTarget.value === "new") {
      this.dialogTarget.showModal()
    } else {
      this.previousValue = this.selectTarget.value
    }
  }

  close() {
    this.selectTarget.value = this.previousValue
    this.dialogTarget.close()
  }

  closeOnSuccess(event) {
    if (!event.detail.success) return

    this.previousValue = this.selectTarget.value
    this.dialogTarget.close()
  }
}
