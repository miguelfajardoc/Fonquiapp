import { Controller } from "@hotwired/stimulus"

// Drives a single confirmation <dialog> shared by every row of a table.
// Each trigger passes the zone's name and delete URL as Stimulus params;
// "open" copies those into the dialog before showing it.
export default class extends Controller {
  static targets = ["dialog", "name", "form"]

  open({ params: { name, url } }) {
    this.nameTarget.textContent = name
    this.formTarget.action = url
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }
}
