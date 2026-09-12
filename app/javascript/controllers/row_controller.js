import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Makes a table row navigate to a URL on click, without affecting
// interactive controls (e.g. a delete button) nested inside the row.
export default class extends Controller {
  visit({ params: { url }, target }) {
    if (target.closest("[data-row-target='skip']")) return

    Turbo.visit(url)
  }
}
