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
    new_archetype
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
