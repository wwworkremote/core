# frozen_string_literal: true

# One application question as observed in one context (ADR 008). Immutable
# evidence: the exact wording and full provenance -- job posting, application,
# guided session, provider, persona, page step, outcome (via associations) --
# are never rewritten. Only the archetype assignment is mutable, and that is a
# separate set of columns, so a reclassification never touches the wording.
class QuestionOccurrence < ApplicationRecord
  SOURCE_KINDS = %w[observed manual_question submitted].freeze
  IMMUTABLE = %w[raw_prompt normalized_prompt question_kind job_posting_id user_id
                 user_job_posting_id guided_session_id provider persona_id page_step
                 field_key source_kind observed_at context].freeze

  belongs_to :job_posting
  belongs_to :user
  belongs_to :user_job_posting, optional: true
  belongs_to :guided_session, optional: true
  belongs_to :question_archetype, optional: true

  validates :raw_prompt, :normalized_prompt, :question_kind, :source_kind, :observed_at, presence: true
  validates :source_kind, inclusion: { in: SOURCE_KINDS }
  validate :evidence_is_immutable, on: :update

  scope :archetyped, -> { where.not(question_archetype_id: nil) }

  # industry has no first-class model; the AI category on the posting is the
  # closest stable proxy (see job_postings/show).
  def industry = job_posting.data&.dig("ai_category")

  def outcome = user_job_posting&.outcome

  private

  def evidence_is_immutable
    changed_evidence = changes.keys & IMMUTABLE
    return if changed_evidence.empty?

    errors.add(:base, "occurrence evidence is immutable: #{changed_evidence.join(', ')}")
  end
end
