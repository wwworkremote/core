# frozen_string_literal: true

# One application question as observed in one context (ADR 008). Immutable
# evidence: the exact wording and full provenance -- job posting, application,
# guided session, provider, persona, page step, outcome (via associations) --
# are never rewritten. Only the archetype assignment is mutable, and that is a
# separate set of columns, so a reclassification never touches the wording.
# == Schema Information
#
# Table name: question_occurrences
#
#  id                         :bigint           not null, primary key
#  archetype_assigned_by      :string
#  archetype_confidence       :integer
#  context                    :jsonb            not null
#  datalake_extractor_version :string
#  field_key                  :string
#  normalized_prompt          :string           not null
#  observed_at                :datetime         not null
#  page_step                  :string
#  provider                   :string
#  question_kind              :string           not null
#  raw_prompt                 :text             not null
#  source_kind                :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  guided_session_id          :bigint
#  job_posting_id             :bigint           not null
#  persona_id                 :string
#  question_archetype_id      :bigint
#  user_id                    :bigint           not null
#  user_job_posting_id        :bigint
#
# Indexes
#
#  idx_question_occurrences_dedupe                      (user_job_posting_id,field_key,normalized_prompt,source_kind) UNIQUE
#  index_question_occurrences_on_guided_session_id      (guided_session_id)
#  index_question_occurrences_on_job_posting_id         (job_posting_id)
#  index_question_occurrences_on_normalized_prompt      (normalized_prompt)
#  index_question_occurrences_on_question_archetype_id  (question_archetype_id)
#  index_question_occurrences_on_user_id                (user_id)
#  index_question_occurrences_on_user_job_posting_id    (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (guided_session_id => guided_sessions.id)
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (question_archetype_id => question_archetypes.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
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
  has_many :answer_proposal_verdicts, dependent: :nullify

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
