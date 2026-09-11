# frozen_string_literal: true

# Turns a captured question -- an ApplicationFieldObservation (from the guided
# recorder / sidepanel) or an ApplicationQuestion (a manual per-posting Q&A) --
# into a durable QuestionOccurrence, and auto-assigns it to a Question
# Archetype by exact normalized-prompt match (ADR 008: deterministic,
# explainable first pass; a human can merge/split later).
#
# Idempotent: re-running never duplicates and never rewrites existing evidence.
class QuestionOccurrences::Record
  # Field kinds that are not really "questions" -- pure identity/contact
  # fields aren't worth an archetype.
  SKIP_KINDS = %w[identity contact].freeze
  PROVIDER_HOSTS = { "greenhouse" => "greenhouse.io", "lever" => "lever.co", "ashby" => "ashbyhq.com",
                     "workday" => "myworkdayjobs.com", "linkedin" => "linkedin.com", "indeed" => "indeed.com" }.freeze

  def self.call(source) = new(source).call

  def initialize(source)
    @source = source
  end

  def call
    attrs = attributes
    return nil unless attrs

    occurrence = QuestionOccurrence.find_by(dedupe_scope(attrs)) || QuestionOccurrence.create!(attrs)
    assign_archetype(occurrence)
    occurrence
  end

  private

  def attributes
    case @source
    when ApplicationFieldObservation then observation_attributes
    when ApplicationQuestion then question_attributes
    end
  end

  # A flat one-key-per-column mapping of the source record -- AbcSize counts
  # each read as a branch. Splitting further would scatter the mapping.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def observation_attributes
    return nil if SKIP_KINDS.include?(@source.question_kind)

    ujp = @source.user_job_posting
    { job_posting_id: ujp.job_posting_id, user_id: ujp.user_id, user_job_posting_id: ujp.id,
      guided_session_id: guided_session_id_for(@source.guided_session_token),
      provider: provider_for(ujp.job_posting, @source.guided_session_token),
      persona_id: @source.persona_id, page_step: @source.page_step,
      field_key: @source.field_key, raw_prompt: @source.field_label, normalized_prompt: @source.normalized_prompt,
      question_kind: @source.question_kind, source_kind: "observed", context: @source.context,
      observed_at: @source.observed_at }
  end

  def question_attributes
    classified = ApplicationFieldQuestionClassifier.call(@source.question_text)
    ujp = @source.user.user_job_postings.find_by(job_posting_id: @source.job_posting_id)
    { job_posting_id: @source.job_posting_id, user_id: @source.user_id, user_job_posting_id: ujp&.id,
      provider: provider_for(@source.job_posting, nil), raw_prompt: @source.question_text,
      normalized_prompt: classified[:normalized_prompt], question_kind: classified[:question_kind],
      source_kind: "manual_question", observed_at: @source.created_at }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def dedupe_scope(attrs)
    attrs.slice(:job_posting_id, :user_id, :normalized_prompt, :source_kind, :field_key)
  end

  def assign_archetype(occurrence)
    return if occurrence.question_archetype_id

    archetype = QuestionArchetype.active.find_by(canonical_prompt: occurrence.normalized_prompt) ||
                QuestionArchetype.create!(archetype_attrs(occurrence))
    stamp_archetype(occurrence, archetype)
  end

  def stamp_archetype(occurrence, archetype)
    # archetype columns only -- the wording stays immutable.
    # rubocop:disable-next Rails/SkipsModelValidations
    occurrence.update_columns(question_archetype_id: archetype.id, archetype_confidence: 100,
                              archetype_assigned_by: "auto:exact_prompt")
  end

  def archetype_attrs(occurrence)
    { label: occurrence.raw_prompt.to_s.truncate(120), canonical_prompt: occurrence.normalized_prompt,
      question_kind: occurrence.question_kind }
  end

  def guided_session_id_for(token)
    token.present? ? GuidedSession.where(session_token: token).pick(:id) : nil
  end

  # Rough but stable: the guided session's own provider, else a known host
  # match on the posting's apply URL, else nil. Good enough for the graph's
  # per-provider view.
  def provider_for(job_posting, token)
    return GuidedSession.where(session_token: token).pick(:provider) if token.present?

    provider_from_host(job_posting.target_url)
  end

  def provider_from_host(url)
    host = URI.parse(url.to_s).host.to_s.downcase
    PROVIDER_HOSTS.find { |_name, suffix| host.end_with?(suffix) }&.first
  rescue URI::InvalidURIError
    nil
  end
end
