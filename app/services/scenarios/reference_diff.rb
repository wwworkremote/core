# frozen_string_literal: true

class Scenarios::ReferenceDiff
  def self.call(candidate, reference:)
    new(candidate, reference: reference).call
  end

  def initialize(candidate, reference:)
    @candidate = candidate
    @reference = reference
  end

  # rubocop:disable-next Metrics/MethodLength -- this is the complete diff interface.
  def call
    {
      provider: @candidate.provider,
      candidate: signature_kinds(@candidate),
      reference: signature_kinds(@reference),
      gained: candidate_kinds - reference_kinds,
      lost: reference_kinds - candidate_kinds,
      reordered: reordered?
    }
  end

  private

  def signature_kinds(scenario)
    return [] unless scenario

    scenario.scenario_signatures.order(:first_observed_at, :id).pluck(:kind)
  end

  def candidate_kinds
    @candidate_kinds ||= signature_kinds(@candidate)
  end

  def reference_kinds
    @reference_kinds ||= signature_kinds(@reference)
  end

  def reordered?
    common_candidate = candidate_kinds & reference_kinds
    common_reference = reference_kinds & candidate_kinds
    common_candidate != common_reference
  end
end
