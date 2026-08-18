import { Controller } from "@hotwired/stimulus"

// Keyboard shortcuts for the one-at-a-time triage queue -- F/N/E click the
// matching decision button, S clicks Skip. Ignored while focus is in the
// note field so typing doesn't accidentally fire a decision.
export default class extends Controller {
  static targets = ["favorite", "ignore", "expire", "skip"]

  keydown(event) {
    if (["INPUT", "TEXTAREA"].includes(event.target.tagName)) return

    const target = { f: "favorite", n: "ignore", e: "expire", s: "skip" }[event.key.toLowerCase()]
    if (target) this[`${target}Target`].click()
  }
}
