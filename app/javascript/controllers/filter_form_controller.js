import { Controller } from "@hotwired/stimulus"

// Debounces the job postings quick-filter form so narrowing the list happens
// live as you type/toggle, without a manual submit -- Enter/the submit
// button still fire immediately via the browser's native form submit.
export default class extends Controller {
  static values = { delay: { type: Number, default: 300 } }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
  }
}
