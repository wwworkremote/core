# frozen_string_literal: true

# Writes value-free AnswerProposalVerdict rows (TASK-127 AC#3). Callers pass
# text; only the sha256 digests + the edit distance are kept -- the answer
# already lives on the occurrence / ApplicationQuestion.
#
# A proposal shown starts as `declined` (shown, not acted on). When the answer
# is edited or submitted the open row flips to `accepted` / `edited` and the
# edit distance is computed while both texts are in hand.
class AnswerProposalVerdicts::Record
  def self.for_generated(question, proposed_text, strategy_source)
    archetype = archetype_for(question.question_text)
    archetype&.answer_proposal_verdicts&.create!(generated_attrs(question, proposed_text, strategy_source))
  end

  # proposed and final are both in hand here -- the only moment edit distance
  # can be measured without keeping the text.
  def self.resolve(question, proposed_text:, final_text:)
    verdict = open_verdict_for(question)
    return unless verdict

    distance = DidYouMean::Levenshtein.distance(proposed_text.to_s, final_text.to_s)
    verdict.update!(final_text_sha256: digest(final_text), edit_distance: distance,
                    verdict: distance.zero? ? "accepted" : "edited")
  end

  # The sidepanel fill path (TASK-127 AC#3): proposed + final both in hand.
  def self.from_fill(question_text:, strategy_source:, proposed_text:, final_text:)
    archetype = archetype_for(question_text.to_s)
    archetype&.answer_proposal_verdicts&.create!(fill_attrs(strategy_source, proposed_text, final_text))
  end

  def self.fill_attrs(strategy_source, proposed_text, final_text)
    distance = DidYouMean::Levenshtein.distance(proposed_text.to_s, final_text.to_s)
    { strategy_source: normalize_source(strategy_source), verdict: distance.zero? ? "accepted" : "edited",
      proposed_text_sha256: digest(proposed_text), final_text_sha256: digest(final_text), edit_distance: distance }
  end

  def self.generated_attrs(question, proposed_text, strategy_source)
    { question_occurrence: occurrence_for(question), persona_id: persona_for(question),
      strategy_source: normalize_source(strategy_source), verdict: "declined",
      proposed_text_sha256: digest(proposed_text) }
  end

  def self.archetype_for(text)
    QuestionArchetype.active.find_by(canonical_prompt: ApplicationFieldQuestionClassifier.normalize(text))
  end

  def self.occurrence_for(question)
    QuestionOccurrence.find_by(job_posting_id: question.job_posting_id, user_id: question.user_id,
                               source_kind: "manual_question",
                               normalized_prompt: ApplicationFieldQuestionClassifier.normalize(question.question_text))
  end

  def self.persona_for(question)
    question.user.user_job_postings.find_by(job_posting_id: question.job_posting_id)&.resume_persona_id
  end

  def self.open_verdict_for(question)
    occurrence = occurrence_for(question)
    occurrence && occurrence.answer_proposal_verdicts.where(verdict: "declined").order(:decided_at).last
  end

  def self.normalize_source(source)
    AnswerProposalVerdict::STRATEGY_SOURCES.include?(source.to_s) ? source.to_s : "ai"
  end

  def self.digest(text) = Digest::SHA256.hexdigest(text.to_s)
end
