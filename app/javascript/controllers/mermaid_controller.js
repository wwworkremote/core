import { Controller } from "@hotwired/stimulus"

// Runs mermaid.js against every .mermaid block inside this element. connect()
// fires again on every Turbo visit (a fresh DOM node each time), which is
// what makes this a Stimulus controller instead of a plain inline <script> --
// Turbo dedupes/skips re-running identical inline scripts across visits, but
// each docs page has different diagram content that needs rendering fresh.
export default class extends Controller {
  connect() {
    if (!window.mermaid) return

    window.mermaid.initialize({ startOnLoad: false, theme: "dark" })
    // suppressErrors: true -- one diagram with a syntax error renders an
    // inline "syntax error" placeholder for just that diagram; false
    // rejects the whole batch's promise and leaves every diagram on the
    // page unrendered, not just the broken one.
    window.mermaid.run({ querySelector: ".mermaid", suppressErrors: true })
  }
}
