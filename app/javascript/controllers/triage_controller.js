import { Controller } from "@hotwired/stimulus"

// Keyboard shortcuts for the one-at-a-time triage queue -- F/N/E click the
// matching decision button, S clicks Skip, B follows the Back link.
// Ignored while focus is in the note field so typing doesn't accidentally
// fire a decision. B has no target when there's no prior triage decision
// this session, so it's checked with hasXTarget rather than clicked blind.
export default class extends Controller {
  static targets = ["favorite", "ignore", "expire", "skip", "back", "heading"]

  connect() {
    // Full-page reload on every decision/skip -- move focus to the new
    // posting's heading so screen readers announce it without relying on
    // the browser's own (often silent) same-URL navigation behavior.
    if (this.hasHeadingTarget) this.headingTarget.focus()
  }

  keydown(event) {
    if (["INPUT", "TEXTAREA"].includes(event.target.tagName)) return

    const target = { f: "favorite", n: "ignore", e: "expire", s: "skip", b: "back" }[event.key.toLowerCase()]
    if (target && this[`has${target[0].toUpperCase()}${target.slice(1)}Target`]) this[`${target}Target`].click()
  }
}
