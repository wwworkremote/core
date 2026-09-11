# frozen_string_literal: true

# Persists one Reference Comparison run (ADR 009): materializes the guided
# session, runs Scenarios::DriftAnalysis, and writes a ReferenceComparison with
# its ComparisonFindings. Every attempt is recorded -- `no_reference` and
# `failed` included. Advisory only: never authorizes or advances the
# application. TASK-119 owns when this runs and how it is shown.
class Scenarios::RecordComparison
  def self.call(guided_session, trigger:)
    new(guided_session, trigger: trigger).call
  end

  def initialize(guided_session, trigger:)
    @guided_session = guided_session
    @trigger = trigger
  end

  def call
    return record(outcome: "no_reference") unless reference

    analysis ? record_with_findings : record(outcome: "failed", error: @error)
  end

  private

  def scenario
    @scenario ||= Scenarios::Capture.from_guided_session(@guided_session)
  end

  def reference_scenario_record
    return @reference_scenario_record if defined?(@reference_scenario_record)

    @reference_scenario_record = ReferenceScenario.find_by(provider: scenario.provider)
  end

  def reference
    reference_scenario_record&.scenario
  end

  def analysis
    return @analysis if defined?(@analysis)

    @analysis = Scenarios::DriftAnalysis.call(scenario, reference: reference, purpose: @guided_session.purpose)
  rescue StandardError => e
    @error = "#{e.class}: #{e.message}"
    @analysis = nil
  end

  def record_with_findings
    comparison = record(outcome: "ok", coverage: analysis[:coverage], rules_version: analysis[:rules_version])
    drift_findings(comparison)
    coverage_findings(comparison)
    comparison
  end

  def record(outcome:, coverage: {}, rules_version: Scenarios::ComparisonRules::VERSION, error: nil)
    ReferenceComparison.create!(base_attrs.merge(outcome: outcome, coverage: coverage,
                                                 comparison_rules_version: rules_version, error: error))
  end

  def base_attrs
    { guided_session: @guided_session, scenario: scenario, reference_scenario: reference_scenario_record,
      provider: scenario.provider, trigger: @trigger }
  end

  def drift_findings(comparison)
    analysis[:drift].each do |change, kinds|
      kinds.each { |kind| add_finding(comparison, drift_attrs(kind, change)) }
    end
  end

  def coverage_findings(comparison)
    applicable_gaps.each { |checkpoint| add_finding(comparison, coverage_attrs(checkpoint)) }
  end

  def applicable_gaps
    Array(analysis.dig(:coverage, :checkpoints)).select { |checkpoint| checkpoint[:status] == "not_reached" }
  end

  def drift_attrs(kind, change)
    { category: "drift", dimension: Scenarios::SignatureKind.for(kind).dimension, locator: kind,
      detail: { change: change.to_s } }
  end

  def coverage_attrs(checkpoint)
    { category: "coverage_gap", dimension: "step", locator: checkpoint[:kind],
      detail: { step: checkpoint[:step] } }
  end

  def add_finding(comparison, attrs)
    comparison.comparison_findings.create!(**attrs, suggested_disposition: carry_forward(attrs))
  end

  def carry_forward(attrs)
    FindingDisposition.latest_for(dimension: attrs[:dimension], locator: attrs[:locator],
                                  provider: scenario.provider, reference_scenario_id: reference_scenario_record&.id)
  end
end
