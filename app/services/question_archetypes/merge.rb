# frozen_string_literal: true

# Merge one Question Archetype into another (ADR 008 AC#2). The source becomes
# a tombstone (`merged_into`) so old references still resolve; its occurrences
# and answer strategies move to the target. Occurrence *wording* is never
# touched -- only the archetype pointer.
#
# The source's latest readiness assessment carries forward onto the target as
# a *suggestion* (assessed_by "merge:carry_forward"), never silently as fact
# (TASK-127).
class QuestionArchetypes::Merge
  def self.call(source:, target:) = new(source, target).call

  def initialize(source, target)
    @source = source
    @target = target
  end

  def call
    raise ArgumentError, "cannot merge an archetype into itself" if @source == @target

    ActiveRecord::Base.transaction { merge_and_tombstone }
    @target
  end

  private

  def merge_and_tombstone
    move_occurrences
    move_strategies
    carry_readiness_forward
    @source.update!(merged_into: @target)
  end

  def carry_readiness_forward
    prior = @source.current_readiness
    @target.readiness_assessments.create!(carry_forward_attrs(prior)) if prior
  end

  def carry_forward_attrs(prior)
    { readiness_class: prior.readiness_class, source_assessment: prior,
      assessed_by: ArchetypeReadinessAssessment::CARRIED_FORWARD_BY,
      rationale: "Carried from merged archetype ##{@source.id} -- confirm or replace." }
  end

  def move_occurrences
    # archetype pointer only -- occurrence wording stays immutable.
    # rubocop:disable-next Rails/SkipsModelValidations
    @source.question_occurrences.update_all(question_archetype_id: @target.id,
                                            archetype_assigned_by: "merge:from_#{@source.id}")
  end

  def move_strategies
    @source.answer_strategies.find_each do |strategy|
      next if @target.answer_strategies.exists?(answer_text: strategy.answer_text, source: strategy.source)

      strategy.update!(question_archetype: @target)
    end
  end
end
