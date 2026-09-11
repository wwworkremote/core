# frozen_string_literal: true

# A reviewable semantic cluster of Question Occurrences (ADR 008). Wording
# variants of the same underlying question live here without being flattened.
# Mergeable and splittable -- see QuestionArchetypes::Merge / ::Split.
# == Schema Information
#
# Table name: question_archetypes
#
#  id               :bigint           not null, primary key
#  canonical_prompt :string           not null
#  label            :string           not null
#  notes            :text
#  question_kind    :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  merged_into_id   :bigint
#
# Indexes
#
#  index_question_archetypes_on_merged_into_id  (merged_into_id)
#  index_question_archetypes_on_question_kind   (question_kind)
#
# Foreign Keys
#
#  fk_rails_...  (merged_into_id => question_archetypes.id)
#
class QuestionArchetype < ApplicationRecord
  belongs_to :merged_into, class_name: "QuestionArchetype", optional: true
  has_many :question_occurrences, dependent: :nullify
  has_many :answer_strategies, dependent: :destroy
  has_many :readiness_assessments, class_name: "ArchetypeReadinessAssessment", dependent: :destroy
  has_many :answer_proposal_verdicts, dependent: :destroy

  validates :label, :canonical_prompt, :question_kind, presence: true

  # Absorbed by a merge -- kept as a tombstone so old references still resolve.
  scope :active, -> { where(merged_into_id: nil) }
  scope :merged, -> { where.not(merged_into_id: nil) }

  def merged? = merged_into_id.present?

  # Distinct wording seen for this archetype, most common first.
  def wording_variants
    question_occurrences.group(:raw_prompt).order(Arel.sql("count(*) desc")).count
  end

  def enabled_strategies = answer_strategies.where(enabled: true)

  # Advisory only (ADR 008 AC#5) -- a sentence for the review page, never a
  # switch. TASK-127 persists the human's decision on top of this.
  def recommended_handling = QuestionArchetypes::Recommendation.call(self)

  # The latest human (or carried-forward) readiness assessment, or nil.
  def current_readiness = ArchetypeReadinessAssessment.current_for(self)

  # Evidence-based suggested default (TASK-127 AC#4) -- Mike sets the real one.
  def suggested_readiness = QuestionArchetypes::SuggestedReadiness.call(self)
end
