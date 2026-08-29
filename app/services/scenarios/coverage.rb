# frozen_string_literal: true

# How much of a provider Reference Scenario's process a guided session reached,
# bounded by the session's purpose (ADR 009). A checkpoint is an ordered
# distinct reference step: marker. For an application_research session every
# checkpoint sequenced after the reference's first commitment_boundary: marker
# is not_applicable -- the boundary is the intentional stopping point, still
# visible. Zero applicable checkpoints => status "unavailable", ratio nil,
# never 0% or 100%.
class Scenarios::Coverage
  RESEARCH = "application_research"

  def self.call(candidate, reference:, purpose:)
    new(candidate, reference: reference, purpose: purpose).call
  end

  def initialize(candidate, reference:, purpose:)
    @candidate = candidate
    @reference = reference
    @purpose = purpose
  end

  def call
    { checkpoints: checkpoints, applicable: applicable.size, reached: reached_count, ratio: ratio, status: status }
  end

  private

  def checkpoints
    @checkpoints ||= reference_steps.map { |sig| checkpoint_for(sig) }
  end

  def checkpoint_for(sig)
    { kind: sig.kind, step: sig.step, status: checkpoint_status(sig) }
  end

  def checkpoint_status(sig)
    return "not_applicable" if research_truncated?(sig)
    return "reached" if candidate_kinds.include?(sig.kind)

    "not_reached"
  end

  def research_truncated?(sig)
    @purpose == RESEARCH && boundary_position && reference_signatures.index(sig) > boundary_position
  end

  def reference_steps
    reference_signatures.select { |sig| marker?(sig, "step") }
  end

  def boundary_position
    return @boundary_position if defined?(@boundary_position)

    @boundary_position = reference_signatures.index { |sig| marker?(sig, "commitment_boundary") }
  end

  def marker?(sig, namespace)
    Scenarios::SignatureKind.for(sig.kind).namespace == namespace
  end

  def reference_signatures
    @reference_signatures ||= ordered(@reference)
  end

  def candidate_kinds
    @candidate_kinds ||= ordered(@candidate).to_set(&:kind)
  end

  def ordered(scenario)
    return [] unless scenario

    scenario.scenario_signatures.order(:first_observed_at, :id).to_a
  end

  def applicable
    @applicable ||= checkpoints.reject { |checkpoint| checkpoint[:status] == "not_applicable" }
  end

  def reached_count = applicable.count { |checkpoint| checkpoint[:status] == "reached" }

  def ratio
    applicable.empty? ? nil : reached_count.fdiv(applicable.size)
  end

  def status
    applicable.empty? ? "unavailable" : "available"
  end
end
