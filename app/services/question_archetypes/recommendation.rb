# frozen_string_literal: true

# Advisory: given the evidence on a Question Archetype, suggest how its answer
# should be handled -- deterministic profile fact, generatable from a template
# or the LLM, or needs a human every time (ADR 008 AC#5). Never fills or
# submits anything; this is a sentence on a review page. TASK-127 refines the
# inputs (edit distance, verdict history) and owns the persisted assessment.
class QuestionArchetypes::Recommendation
  Result = Data.define(:handling, :confidence, :rationale)

  # question_kind (from ApplicationFieldQuestionClassifier) is the strongest
  # cheap signal for how much reasoning an answer needs.
  BY_KIND = { "eligibility" => "deterministic", "logistics" => "deterministic", "contact" => "deterministic",
              "identity" => "deterministic", "experience" => "generatable", "motivation" => "needs_human",
              "demographic" => "needs_human", "free_text" => "needs_human" }.freeze
  SAMPLE_FLOOR = 2

  def self.call(archetype) = new(archetype).call

  def initialize(archetype)
    @archetype = archetype
  end

  def call
    return low_evidence if occurrence_count < SAMPLE_FLOOR

    handling = BY_KIND.fetch(@archetype.question_kind, "generatable")
    Result.new(handling: handling, confidence: confidence(handling), rationale: rationale(handling))
  end

  private

  def occurrence_count = @archetype.question_occurrences.count

  def company_count = @archetype.question_occurrences.distinct.count(:job_posting_id)

  def low_evidence
    Result.new(handling: "needs_human", confidence: 20,
               rationale: "Only #{occurrence_count} occurrence(s) so far -- not enough to recommend reuse.")
  end

  def confidence(handling)
    base = handling == "needs_human" ? 60 : 45
    base + [company_count * 8, 35].min
  end

  def rationale(handling)
    "#{occurrence_count} occurrences across #{company_count} companies; " \
      "kind '#{@archetype.question_kind}' → #{handling.tr('_', ' ')}. " \
      "#{@archetype.enabled_strategies.any? ? 'An answer strategy exists.' : 'No answer strategy yet.'}"
  end
end
