# frozen_string_literal: true

# Turns a HAR or DOM capture into a real Scenario + ScenarioSignature rows
# -- the path Applications::RowImporter never grows, since Scenario is
# scoped to deliberate verification captures, not the routine
# LinkedIn/Greenhouse/Indeed backfill. See
# docs/architecture/signature-registry.md.
#
# Structurally mirrors Applications::RowImporter's split: RowImporter reads
# one already-extracted row per provider; this reads a whole HAR/DOM capture
# and extracts every known identity in one pass, since a single recording
# can surface several different ScenarioSignature kinds at once (a job id in
# a URL, an ats_application_id in a JSON response body, ...). Which kinds to
# look for per provider comes straight from
# Scenarios::HandshakeCheck::SIGNATURE_EXPECTATIONS -- the source of truth
# for which signatures matter per provider.
#
# Idempotent: pass the same Scenario back in via `scenario:` (e.g. a second
# page of the same recorded session, or a literal re-run of the same file)
# and re-observing the same (kind, value) is a no-op, enforced by the
# scenario_signatures unique index. A new (kind, value) under a kind already
# seen is recorded as a new row on purpose -- append-only, same convention
# ApplicationFieldMapping already uses, so a mid-flow id change is visible
# rather than silently overwritten.
#
# ponytail: the extraction patterns below are inferred from this codebase's
# existing RowImporter field/URL knowledge (proven correct) plus the
# publicly documented shape of each provider's own URLs -- ats_application_id
# and candidate_id specifically have no real captured sample to verify
# against yet. Golden-master by design (see "Reference Scenario" in the
# doc): the first real capture against each provider is what confirms or
# corrects these, not a guess frozen in place.
class Scenarios::Capture
  PATTERNS = {
    "linkedin" => {
      "job_id" => [%r{/jobs/view/(\d+)}]
    },
    "greenhouse" => {
      "job_post_id" => [
        %r{greenhouse\.io/[^/\s"]+/jobs/(\d+)},
        /"job_post_id"\s*:\s*"?(\d+)"?/,
        /data-job-post-id=["']([^"']+)["']/i
      ],
      "ats_application_id" => [
        /"ats_application_id"\s*:\s*"?([\w-]+)"?/i,
        /"application_id"\s*:\s*"?([\w-]+)"?/i,
        /data-ats-application-id=["']([^"']+)["']/i
      ]
    },
    "indeed" => {
      "job_key" => [/[?&]jk=([0-9a-f]{10,20})/i, /"jobKey"\s*:\s*"([^"]+)"/]
    },
    "workday" => {
      "tenant_id" => [%r{https://([\w-]+)\.wd\d*\.myworkdayjobs\.com}],
      "candidate_id" => [/"candidateId"\s*:\s*"?([\w-]+)"?/i]
    }
  }.freeze

  # scenario_attrs: passed straight to Scenario.create! when no existing
  # `scenario:` is given (started_at, resume_persona_id, user_job_posting)
  # -- bundled into one hash rather than its own keyword per field, since
  # this service only ever forwards them, it doesn't interpret them.
  def self.call(source, provider:, scenario: nil, scenario_attrs: {})
    new(source, provider: provider, scenario: scenario, scenario_attrs: scenario_attrs).call
  end

  # Materialize a guided session into a Scenario -- the value-free entry path
  # for Reference Comparison (ADR 009). Delegates to Scenarios::GuidedCapture.
  def self.from_guided_session(guided_session)
    Scenarios::GuidedCapture.call(guided_session)
  end

  def initialize(source, provider:, scenario: nil, scenario_attrs: {})
    @source = source
    @provider = provider
    @scenario = scenario
    @scenario_attrs = scenario_attrs
  end

  def call
    scenario = @scenario || build_scenario
    extracted_signatures.each { |kind, value| record_signature(scenario, kind, value) }
    scenario
  end

  private

  def build_scenario
    Scenario.create!({ provider: @provider, started_at: Time.current }.merge(@scenario_attrs))
  end

  def record_signature(scenario, kind, value)
    scenario.scenario_signatures.find_or_create_by!(kind: kind, value: value) do |signature|
      signature.first_observed_at = Time.current
    end
  end

  def extracted_signatures
    PATTERNS.fetch(@provider, {}).filter_map do |kind, patterns|
      value = patterns.filter_map { |pattern| searchable_text[pattern, 1] }.first
      [kind, value] if value
    end
  end

  # A HAR file and a saved DOM capture are both text -- every URL and JSON
  # body a HAR entry carries appears as a literal substring of the file
  # (unless base64-encoded, decoded here), and a saved DOM's hrefs are
  # literal text too. One regex pass over this covers both formats without
  # branching on which one was handed in.
  def searchable_text
    @searchable_text ||= parsed_har ? text_from_har : @source.to_s
  end

  def text_from_har
    entries = parsed_har.dig("log", "entries") || []
    entries.flat_map { |entry| [entry.dig("request", "url"), body_of(entry)] }.compact.join("\n")
  end

  # HAR response bodies arrive either as plain text or base64 -- Chrome
  # mixes both within a single capture (see bin/import_greenhouse_applications).
  def body_of(entry)
    text = entry.dig("response", "content", "text").to_s
    return nil if text.empty?

    entry.dig("response", "content", "encoding") == "base64" ? Base64.decode64(text) : text
  rescue ArgumentError
    nil
  end

  def parsed_har
    return @parsed_har if defined?(@parsed_har)

    parsed = JSON.parse(@source)
    @parsed_har = parsed.is_a?(Hash) && parsed.key?("log") ? parsed : nil
  rescue JSON::ParserError, TypeError
    @parsed_har = nil
  end
end
