# frozen_string_literal: true

# Materializes a GuidedSession into an ordinary Scenario + ScenarioSignature
# rows so Reference Comparison reuses ReferenceDiff / HandshakeCheck / promotion
# (ADR 009). Reads only the value-free GuidedSessionEvent evidence -- never raw
# DOM/HAR. Deterministic and idempotent: re-running reuses guided_session.scenario
# and the (scenario_id, kind, value) unique index no-ops repeats.
#
# Namespaced kinds emitted (all through Scenarios::SignatureKind):
#   step:<phase>.<n>           one per event, in occurred_at order
#   commitment_boundary:<kind> one per irreversible event
#   field:<field_key>          one per observed non-screening form field
#   screening_question:v1:<h>  one per observed screening question
# plus any bare ATS identity kinds the provider's Capture::PATTERNS match.
class Scenarios::GuidedCapture
  UNKNOWN_PROVIDER = "unknown"

  # Where one signature came from -- carried as a unit so the writer stays
  # inside the 4-parameter limit and the source hash is built in one place.
  Origin = Data.define(:event, :extracted_from, :step) do
    def observed_at = event.occurred_at

    def source_hash
      { "guided_session_event_id" => event.id, "extracted_from" => extracted_from }
    end
  end

  def self.call(guided_session)
    new(guided_session).call
  end

  def initialize(guided_session)
    @guided_session = guided_session
    @phase_counts = Hash.new(0)
  end

  def call
    events.each { |event| capture_event(event) }
    scenario
  end

  private

  def scenario
    @scenario ||= @guided_session.scenario || create_scenario
  end

  def create_scenario
    Scenario.create!(provider: canonical_provider, started_at: @guided_session.started_at,
                     guided_session_token: @guided_session.session_token,
                     user_job_posting: @guided_session.user_job_posting).tap do |record|
      @guided_session.update!(scenario: record)
    end
  end

  def events
    @events ||= @guided_session.guided_session_events.order(:occurred_at, :id).to_a
  end

  def canonical_provider
    @canonical_provider ||=
      events.filter_map { |e| e.evidence["provider"] }.find { |p| p != UNKNOWN_PROVIDER } || @guided_session.provider
  end

  def capture_event(event)
    record_step(event)
    record_boundary(event) if event.reversibility == "irreversible"
    record_ats_ids(event)
    record_fields(event)
  end

  def record_fields(event)
    Array(event.evidence["fields"]).each_with_index { |field, i| record_field(event, field, i) }
  end

  def record_step(event)
    label = "#{event.phase}.#{@phase_counts[event.phase] += 1}"
    record_signature(kind: "step:#{label}", value: event.kind, origin: origin(event, "kind", label))
  end

  def record_boundary(event)
    record_signature(kind: "commitment_boundary:#{event.kind}", value: event.approval_state,
                     origin: origin(event, "approval_state"))
  end

  def record_field(event, field, index)
    record_signature(kind: field_kind(field), value: field_shape(field),
                     origin: origin(event, "evidence.fields[#{index}]", event.phase))
  end

  def field_kind(field)
    return Scenarios::SignatureKind.screening_question(field["label"]) if screening_question?(field)

    Scenarios::SignatureKind.build("field", field["field_key"])
  end

  def screening_question?(field)
    field["classification"] == "screening_question"
  end

  def field_shape(field)
    "#{field['type']}|#{field['classification']}|#{field['required'] ? 'required' : 'optional'}"
  end

  def record_ats_ids(event)
    text = ats_text(event)
    ats_patterns.each do |kind, patterns|
      value = first_match(patterns, text)
      record_signature(kind: kind, value: value, origin: origin(event, "page_url")) if value
    end
  end

  def ats_text(event)
    "#{event.page_url}\n#{event.evidence.to_json}"
  end

  def first_match(patterns, text)
    patterns.filter_map { |regexp| text[regexp, 1] }.first
  end

  def ats_patterns
    Scenarios::Capture::PATTERNS.fetch(canonical_provider, {})
  end

  def origin(event, extracted_from, step = nil)
    Origin.new(event: event, extracted_from: extracted_from, step: step)
  end

  def record_signature(kind:, value:, origin:)
    scenario.scenario_signatures.find_or_create_by!(kind: kind, value: value) do |sig|
      sig.first_observed_at = origin.observed_at
      sig.step = origin.step
      sig.source = origin.source_hash
    end
  end
end
