# frozen_string_literal: true

# TASK-126 AC#8: a repeatable proof that a guided session produces a datalake
# bundle dir + manifest -- one asset set per GuidedSessionEvent, a failed
# capture landing as a gap, and every event pointed back at its assets.
# Rails-side simulation; the real extension path is dogfooded separately.
class Datalake::SandboxWalkthrough
  KINDS = %w[page_arrived application_page_arrived submission_attempted].freeze

  def self.call = new.call

  def initialize
    @session = GuidedSession.create!(source_url: "https://boards.greenhouse.io/dl-sandbox/jobs/1",
                                     purpose: "application_execution")
    @store = Datalake::AssetStore.new(@session.session_token)
  end

  def call
    walk
    report
  ensure
    @store.purge!
  end

  private

  def walk
    events = KINDS.map { |kind| record_event(kind) }
    events.each { |event| capture_dom(event) }
    @store.write_gap(type: "har", event_id: events.last.id, reason: "debugger path not exercised in sandbox")
  end

  def record_event(kind)
    irreversible = kind == "submission_attempted"
    @session.guided_session_events.create!(event_attrs(kind, irreversible))
  end

  def event_attrs(kind, irreversible)
    { kind: kind, action: kind.humanize, intent: "walk the flow", requirement: "recommended",
      reversibility: irreversible ? "irreversible" : "reversible",
      approval_state: irreversible ? "pending" : "not_required",
      phase: irreversible ? "reorientation" : "resolution", occurred_at: Time.current }
  end

  def capture_dom(event)
    entry = @store.write_asset(type: "dom", event_id: event.id, bytes: "<html><!-- #{event.kind} --></html>")
    event.note_datalake_asset(entry["seq"])
  end

  def report
    manifest = @store.manifest
    { session_token: @session.session_token, assets: manifest["assets"].size, gaps: manifest["gaps"].size,
      every_event_pointed: pointers_intact? }
  end

  def pointers_intact?
    @session.guided_session_events.all? { |event| event.evidence["datalake_asset_seqs"].present? }
  end
end
