import "@hotwired/turbo-rails"
import "controllers"
import "ahoy"

// ahoy.js only fires on DOMContentLoaded, which Turbo Drive navigations
// after the first don't trigger -- track each one via turbo:load instead.
document.addEventListener("turbo:load", () => window.ahoy.trackView())

// Click/submit delegation raced the request thread in Cuprite system specs
// (button_to's own POST vs. ahoy's tracking POST), intermittently causing
// have_enqueued_job checks to see 0 jobs. Layout only sets this flag outside
// RAILS_ENV=test.
if (window.ahoyTrackInteractions) {
  window.ahoy.trackClicks("a, button, input[type=submit]")
  window.ahoy.trackSubmits("form")
}
