# frozen_string_literal: true

# Reports whether a Scenario's captured ScenarioSignatures satisfy what its
# provider requires -- see docs/architecture/signature-registry.md. Makes
# TASK-83 AC #7 ("every selector verified against a live capture") checkable
# instead of eyeballed: a captured session either produced what the provider
# requires, or this names exactly what's missing.
class Scenarios::HandshakeCheck
  # Per-provider signature kinds and whether each is required. A kind absent
  # from a provider's hash is simply not expected -- neither required nor
  # optional, just unrelated to that provider.
  #
  # ponytail: :required_after_submit is tracked as a distinct requirement
  # level but checked as plain :required for now -- this doesn't yet know
  # which step a scenario reached, only which kinds it observed. Upgrade to
  # step-aware once a scenario with a real pre-submit/post-submit split
  # shows the plain check giving a false "missing."
  SIGNATURE_EXPECTATIONS = {
    "linkedin" => { "job_id" => :required },
    "greenhouse" => { "job_post_id" => :required, "ats_application_id" => :required_after_submit },
    "indeed" => { "job_key" => :required },
    "workday" => { "tenant_id" => :required, "candidate_id" => :optional }
  }.freeze

  def self.call(scenario)
    new(scenario).call
  end

  def initialize(scenario)
    @scenario = scenario
  end

  def call
    expectations.map { |kind, requirement| result_for(kind, requirement) }
  end

  private

  def expectations
    SIGNATURE_EXPECTATIONS.fetch(@scenario.provider, {})
  end

  def result_for(kind, requirement)
    present = observed_kinds.include?(kind)
    { kind: kind, requirement: requirement, present: present, status: status_for(requirement, present) }
  end

  def observed_kinds
    @observed_kinds ||= @scenario.scenario_signatures.distinct.pluck(:kind)
  end

  def status_for(requirement, present)
    return present ? "optional-and-present" : "optional-and-missing" if requirement == :optional

    present ? "required-and-present" : "required-and-missing"
  end
end
