# frozen_string_literal: true

# A reviewable semantic cluster of Question Occurrences (ADR 008). Wording
# variants of the same underlying question live here without being flattened.
# Mergeable and splittable -- see QuestionArchetypes::Merge / ::Split.
class QuestionArchetype < ApplicationRecord
  belongs_to :merged_into, class_name: "QuestionArchetype", optional: true
  has_many :question_occurrences, dependent: :nullify
  has_many :answer_strategies, dependent: :destroy

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
end
