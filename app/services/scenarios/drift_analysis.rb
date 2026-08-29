# frozen_string_literal: true

# The full advisory comparison of a materialized guided-session Scenario against
# its provider Reference Scenario (ADR 009): coverage (how far a purpose-bounded
# run reached) kept distinct from drift (differences within what it actually
# observed). Returns a plain hash; persistence is the ReferenceComparison model
# (TASK-117). Never authorizes, blocks, or advances anything.
class Scenarios::DriftAnalysis
  def self.call(candidate, reference:, purpose:)
    new(candidate, reference: reference, purpose: purpose).call
  end

  def initialize(candidate, reference:, purpose:)
    @candidate = candidate
    @reference = reference
    @purpose = purpose
  end

  def call
    {
      rules_version: Scenarios::ComparisonRules::VERSION,
      coverage: coverage,
      drift: { gained: diff[:gained], lost: lost_in_scope, changed: diff[:changed] }
    }
  end

  private

  def diff
    @diff ||= Scenarios::ReferenceDiff.call(@candidate, reference: @reference)
  end

  def coverage
    @coverage ||= Scenarios::Coverage.call(@candidate, reference: @reference, purpose: @purpose)
  end

  # A reference-only kind is drift only within Reached Scope -- a marker the run
  # should have produced by where it got. Past the last reached reference
  # position it is a coverage gap, not drift.
  def lost_in_scope
    diff[:lost] & reached_scope_kinds.to_a
  end

  def reached_scope_kinds
    return Set.new unless last_reached_index

    @reached_scope_kinds ||= diff[:reference][0..last_reached_index].to_set
  end

  def last_reached_index
    return @last_reached_index if defined?(@last_reached_index)

    @last_reached_index = diff[:reference].rindex { |kind| candidate_kinds.include?(kind) }
  end

  def candidate_kinds
    @candidate_kinds ||= diff[:candidate].to_set
  end
end
