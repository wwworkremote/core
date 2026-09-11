import { Controller } from "@hotwired/stimulus"

// Cmd+K / Ctrl+K command palette (TASK-76) -- fuzzy-searches a route index
// built server-side by CommandIndex, the app's route set already being the
// sitemap. Uses a native <dialog> so focus-trap and Escape-to-close come
// from the browser, not hand-rolled JS.
export default class extends Controller {
  static targets = ["dialog", "input", "results"]
  static values = { index: Array }

  connect() {
    this.selectedIndex = 0
    this.recent = this.loadRecent()
  }

  globalKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault()
      this.open()
    }
  }

  open() {
    this.dialogTarget.showModal()
    this.inputTarget.value = ""
    this.selectedIndex = 0
    this.renderResults(this.currentResults())
    this.inputTarget.focus()
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  filter() {
    this.selectedIndex = 0
    this.renderResults(this.currentResults())
  }

  onKeydown(event) {
    if (event.key === "ArrowDown") { event.preventDefault(); this.move(1) } // eslint-disable-line
    else if (event.key === "ArrowUp") { event.preventDefault(); this.move(-1) } // eslint-disable-line
    else if (event.key === "Enter") { event.preventDefault(); this.navigateSelected() }
  }

  move(delta) {
    const results = this.currentResults()
    if (!results.length) return
    this.selectedIndex = (this.selectedIndex + delta + results.length) % results.length
    this.renderResults(results)
  }

  navigateSelected() {
    const entry = this.currentResults()[this.selectedIndex]
    if (entry) this.visit(entry)
  }

  navigateClicked(event) {
    const entry = this.currentResults()[Number(event.currentTarget.dataset.index)]
    if (entry) this.visit(entry)
  }

  hover(event) {
    this.selectedIndex = Number(event.currentTarget.dataset.index)
    this.renderResults(this.currentResults())
  }

  visit(entry) {
    this.saveRecent(entry)
    window.location = entry.path
  }

  currentResults() {
    const query = this.inputTarget.value.trim()
    return query ? this.scoredMatches(query) : this.recentEntries()
  }

  recentEntries() {
    const byPath = Object.fromEntries(this.indexValue.map(e => [e.path, e]))
    return this.recent.map(path => byPath[path]).filter(Boolean)
  }

  scoredMatches(query) {
    const q = query.toLowerCase()
    return this.indexValue
      .map(entry => ({ entry, score: this.score(entry.label.toLowerCase(), q) }))
      .filter(({ score }) => score > 0)
      .sort((a, b) => b.score - a.score)
      .map(({ entry }) => entry)
  }

  // Contiguous substring match, earlier position scores higher. Not a full
  // fuzzy-subsequence matcher -- ~40 routes doesn't need one, and a simple
  // scorer is easier to reason about than a fuzzy-matching dependency.
  score(label, query) {
    const index = label.indexOf(query)
    return index === -1 ? 0 : 100 - index
  }

  renderResults(results) {
    const rows = results.map((entry, i) => `
      <li>
        <button type="button" data-index="${i}"
            data-action="click->command-palette#navigateClicked mouseenter->command-palette#hover"
            class="w-full text-left px-4 py-3 rounded-lg font-bold text-sm ${i === this.selectedIndex ? "bg-primary text-primary-content" : "text-base-content hover:bg-white/5"}">
          ${entry.label}
        </button>
      </li>
    `).join("")

    this.resultsTarget.innerHTML = rows ||
      `<li class="px-4 py-6 text-center text-xs text-slate-500 font-bold">No matches</li>`
  }

  loadRecent() {
    try {
      return JSON.parse(localStorage.getItem("wwr_command_recent") || "[]")
    } catch (_error) {
      return []
    }
  }

  saveRecent(entry) {
    this.recent = [entry.path, ...this.recent.filter(p => p !== entry.path)].slice(0, 8)
    localStorage.setItem("wwr_command_recent", JSON.stringify(this.recent))
  }
}
