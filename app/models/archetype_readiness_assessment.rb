# frozen_string_literal: true

# Append-only record of how ready a Question Archetype's answers are to be
# automated -- deterministic / generatable / needs_human (TASK-127, shape from
# wayfinder doc-7 TASK-124). Mirrors FindingDisposition (ADR 009): the latest
# applicable row wins for presentation, history is never overwritten, and a
# carried-forward row (after a merge/split) is a *suggestion*, not a fact.
#
# HARD GUARDRAIL (Bounded Agency): a readiness_class is never consumed to fill
# or submit an answer. It only ever means "propose without a review prompt".
# == Schema Information
#
# Table name: archetype_readiness_assessments
#
#  id                    :bigint           not null, primary key
#  assessed_at           :datetime         not null
#  assessed_by           :string           not null
#  rationale             :text
#  readiness_class       :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  question_archetype_id :bigint           not null
#  source_assessment_id  :bigint
#
# Indexes
#
#  idx_on_question_archetype_id_assessed_at_f44acfd079             (question_archetype_id,assessed_at)
#  index_archetype_readiness_assessments_on_question_archetype_id  (question_archetype_id)
#  index_archetype_readiness_assessments_on_source_assessment_id   (source_assessment_id)
#
# Foreign Keys
#
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#  fk_rails_...  (source_assessment_id => archetype_readiness_assessments.id)
#
class ArchetypeReadinessAssessment < ApplicationRecord
  CLASSES = %w[deterministic generatable needs_human].freeze
  CARRIED_FORWARD_BY = "merge:carry_forward"

  belongs_to :question_archetype
  belongs_to :source_assessment, class_name: "ArchetypeReadinessAssessment", optional: true

  validates :readiness_class, inclusion: { in: CLASSES }
  validates :assessed_by, presence: true
  validates :assessed_at, presence: true

  before_validation { self.assessed_at ||= Time.current }

  scope :newest_first, -> { order(assessed_at: :desc, id: :desc) }

  def self.current_for(archetype)
    where(question_archetype_id: archetype.id).newest_first.first
  end

  # A carried-forward row is advisory until a human re-affirms it.
  def carried_forward? = assessed_by == CARRIED_FORWARD_BY

  # Immutable after creation.
  def readonly? = persisted?
end
