# frozen_string_literal: true

# Split a subset of an archetype's occurrences off into a new archetype
# (ADR 008 AC#2) -- for when the deterministic exact-prompt clustering lumped
# two genuinely different questions together. Wording is never touched.
class QuestionArchetypes::Split
  def self.call(archetype:, occurrence_ids:, label: nil) = new(archetype, occurrence_ids, label).call

  def initialize(archetype, occurrence_ids, label)
    @archetype = archetype
    @occurrences = archetype.question_occurrences.where(id: occurrence_ids)
    @label = label
  end

  def call
    validate!
    ActiveRecord::Base.transaction { move_to_new_archetype }
  end

  private

  def move_to_new_archetype
    new_archetype = QuestionArchetype.create!(new_archetype_attrs)
    # rubocop:disable-next Rails/SkipsModelValidations -- archetype pointer only
    @occurrences.update_all(question_archetype_id: new_archetype.id,
                            archetype_assigned_by: "split:from_#{@archetype.id}")
    carry_readiness_forward(new_archetype)
    new_archetype
  end

  # The parent's readiness is a starting suggestion for the split-off cluster
  # (TASK-127) -- advisory, assessed_by "merge:carry_forward", never a fact.
  def carry_readiness_forward(new_archetype)
    prior = @archetype.current_readiness
    new_archetype.readiness_assessments.create!(carry_forward_attrs(prior)) if prior
  end

  def carry_forward_attrs(prior)
    { readiness_class: prior.readiness_class, source_assessment: prior,
      assessed_by: ArchetypeReadinessAssessment::CARRIED_FORWARD_BY,
      rationale: "Carried from parent archetype ##{@archetype.id} on split -- confirm or replace." }
  end

  def validate!
    raise ArgumentError, "no matching occurrences to split off" if @occurrences.empty?
    return unless @occurrences.count == @archetype.question_occurrences.count
    raise ArgumentError,
          "cannot split off every occurrence"
  end

  def new_archetype_attrs
    sample = @occurrences.first
    { label: @label.presence || sample.raw_prompt.to_s.truncate(120),
      canonical_prompt: sample.normalized_prompt, question_kind: sample.question_kind,
      notes: "Split from ##{@archetype.id} (#{@archetype.label})" }
  end
end
