import { Controller } from "@hotwired/stimulus"

// Auto-dismisses a toast a fixed delay after it appears (e.g. via Turbo
// Stream prepend) -- ponytail: fixed delay, no pause-on-hover/queueing,
// add if toast volume ever makes that matter.
export default class extends Controller {
  static values = { ms: { type: Number, default: 5000 } }

  connect() {
    this.timeout = setTimeout(() => this.element.remove(), this.msValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
