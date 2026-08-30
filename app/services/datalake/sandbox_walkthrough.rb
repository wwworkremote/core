# frozen_string_literal: true

# TASK-126 AC#8 / TASK-134 AC#4: a repeatable proof that a guided session
# produces a datalake bundle dir + manifest -- one asset set per
# GuidedSessionEvent, a failed capture landing as a gap, every event pointed
# back at its assets. Runs both purposes: an application_execution bundle
# carries har + full-page screenshot asset types (the chrome.debugger path),
# an application_research bundle carries only the light set (no har, no
# debugger banner). Rails-side simulation; the real extension path is
# dogfooded separately.
class Datalake::SandboxWalkthrough
  SANDBOX_URL = "https://boards.greenhouse.io/dl-sandbox/jobs/1"
  KINDS = %w[page_arrived application_page_arrived submission_attempted].freeze
  LIGHT = %w[dom screenshot].freeze
  HEAVY = %w[dom har screenshot].freeze

  def self.call = new.call

  def call
    { execution: walk("application_execution", HEAVY), research: walk("application_research", LIGHT) }
  end

  private

  def walk(purpose, asset_types)
    session, store = bundle_for(purpose)
    capture(session, store, asset_types)
    report(session, store)
  ensure
    store&.purge!
  end

  def bundle_for(purpose)
    session = GuidedSession.create!(source_url: SANDBOX_URL, purpose: purpose)
    [session, Datalake::AssetStore.new(session.session_token)]
  end

  def capture(session, store, asset_types)
    events = KINDS.map { |kind| record_event(session, kind) }
    events.each { |event| asset_types.each { |type| write(store, event, type) } }
    detach_gap(store, events.last) if asset_types.include?("har")
  end

  # The last event's har is lost the way onDetach loses it mid-session.
  def detach_gap(store, event)
    store.write_gap(type: "har", event_id: event.id, reason: "chrome.debugger detached (DevTools opened)")
  end

  def write(store, event, type)
    entry = store.write_asset(type: type, event_id: event.id, bytes: sample_bytes(type, event))
    event.note_datalake_asset(entry["seq"])
  end

  def sample_bytes(type, event)
    return "<html><!-- #{event.kind} --></html>" if type == "dom"
    return %({"log":{"version":"1.2","entries":[]}}) if type == "har"

    "\x89PNG\r\n#{event.kind}".b
  end

  def record_event(session, kind)
    irreversible = kind == "submission_attempted"
    session.guided_session_events.create!(event_attrs(kind, irreversible))
  end

  def event_attrs(kind, irreversible)
    { kind: kind, action: kind.humanize, intent: "walk the flow", requirement: "recommended",
      reversibility: irreversible ? "irreversible" : "reversible",
      approval_state: irreversible ? "pending" : "not_required",
      phase: irreversible ? "reorientation" : "resolution", occurred_at: Time.current }
  end

  def report(session, store)
    store.summary.merge(session_token: session.session_token, every_event_pointed: every_event_pointed?(session))
  end

  def every_event_pointed?(session)
    session.guided_session_events.all? { |event| event.evidence["datalake_asset_seqs"].present? }
  end
end
