# frozen_string_literal: true

# Kind-level diff of a candidate Scenario against a provider Reference Scenario
# (ADR 009). Works over every signature kind -- bare ATS identities and the
# namespaced structural markers alike -- classified through
# Scenarios::SignatureKind. This is the raw diff; Reached-Scope filtering and
# the coverage split live in Scenarios::DriftAnalysis / Scenarios::Coverage.
class Scenarios::ReferenceDiff
  DIMENSIONS = %w[ats_identity field screening_question step commitment_boundary unknown_namespace].freeze

  def self.call(candidate, reference:)
    new(candidate, reference: reference).call
  end

  def initialize(candidate, reference:)
    @candidate = candidate
    @reference = reference
  end

  def call
    rollup.merge(changed: changed, dimensions: dimensions)
  end

  private

  # rubocop:disable-next Metrics/MethodLength -- the all-kinds rollup, kept flat.
  def rollup
    {
      provider: @candidate.provider,
      candidate: signature_kinds(@candidate),
      reference: signature_kinds(@reference),
      gained: candidate_kinds - reference_kinds,
      lost: reference_kinds - candidate_kinds,
      reordered: reordered?
    }
  end

  def signature_kinds(scenario)
    return [] unless scenario

    scenario.scenario_signatures.order(:first_observed_at, :id).pluck(:kind)
  end

  def latest_values(scenario)
    return {} unless scenario

    scenario.scenario_signatures.order(:first_observed_at, :id).to_h { |sig| [sig.kind, sig.value] }
  end

  def candidate_kinds = @candidate_kinds ||= signature_kinds(@candidate)
  def reference_kinds = @reference_kinds ||= signature_kinds(@reference)
  def candidate_values = @candidate_values ||= latest_values(@candidate)
  def reference_values = @reference_values ||= latest_values(@reference)

  def common_value_kinds = candidate_values.keys & reference_values.keys

  def changed
    common_value_kinds.reject { |kind| candidate_values[kind] == reference_values[kind] }
  end

  def dimensions
    DIMENSIONS.index_with { |dimension| bucket(dimension) }
  end

  def bucket(dimension)
    {
      gained: in_dimension(rollup[:gained], dimension),
      lost: in_dimension(rollup[:lost], dimension),
      changed: in_dimension(changed, dimension)
    }
  end

  def in_dimension(kinds, dimension)
    kinds.select { |kind| Scenarios::SignatureKind.for(kind).dimension == dimension }
  end

  def reordered?
    (candidate_kinds & reference_kinds) != (reference_kinds & candidate_kinds)
  end
end
