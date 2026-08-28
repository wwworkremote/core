import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["current", "event", "phase", "position"]
  static values = { playbackUrl: String, position: Number }

  connect() {
    this.timer = null
    this.render()
  }

  disconnect() {
    this.pause()
  }

  play() {
    if (this.timer || this.positionValue >= this.eventTargets.length) return

    this.timer = setInterval(() => this.advance(), 1400)
  }

  pause() {
    if (!this.timer) return

    clearInterval(this.timer)
    this.timer = null
  }

  async previous() {
    this.pause()
    this.positionValue = Math.max(0, this.positionValue - 1)
    this.render()
    await this.persist()
  }

  async next() {
    this.pause()
    this.positionValue = Math.min(this.eventTargets.length, this.positionValue + 1)
    this.render()
    await this.persist()
  }

  async advance() {
    this.positionValue += 1
    this.render()
    await this.persist()
    if (this.positionValue >= this.eventTargets.length) this.pause()
  }

  render() {
    const activeIndex = this.positionValue - 1
    const activeEvent = this.eventTargets[activeIndex]

    this.eventTargets.forEach((event, index) => {
      event.classList.toggle("ring-2", index === activeIndex)
      event.classList.toggle("ring-primary", index === activeIndex)
      event.classList.toggle("opacity-50", index > activeIndex)
    })

    this.phaseTargets.forEach((phase) => {
      phase.classList.toggle("border-primary", phase.dataset.phase === activeEvent?.dataset.phase)
      phase.classList.toggle("bg-primary/10", phase.dataset.phase === activeEvent?.dataset.phase)
    })

    this.currentTarget.textContent = activeEvent?.querySelector(".text-white")?.textContent ||
      (this.eventTargets.length ? "Ready to replay the first transition" : "Ready to begin the lap")
    this.positionTarget.textContent = `Playback position: ${this.positionValue}`
  }

  async persist() {
    const token = document.querySelector("meta[name='csrf-token']")?.content
    const response = await fetch(this.playbackUrlValue, {
      method: "PATCH",
      credentials: "same-origin",
      headers: { "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": token },
      body: new URLSearchParams({ position: String(this.positionValue), authenticity_token: token }),
    })
    if (!response.ok) throw new Error(`Playback save failed (${response.status})`)
  }
}
