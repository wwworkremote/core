# frozen_string_literal: true

# Advisory suggested-default readiness class for a Question Archetype
# (TASK-127 AC#4). Inputs: verdict sample size (below the floor -> needs_human),
# verbatim-acceptance rate, historical median edit distance, and occurrence
# spread across companies. Mike sets the real class -- this is never
# auto-applied and is never used to fill or submit an answer.
class QuestionArchetypes::SuggestedReadiness
  Result = Data.define(:readiness_class, :rationale)

  SAMPLE_FLOOR = 5
  DETERMINISTIC_KINDS = %w[eligibility logistics contact identity].freeze

  def self.call(archetype) = new(archetype).call

  def initialize(archetype)
    @archetype = archetype
    @verdicts = AnswerProposalVerdict.where(question_archetype_id: archetype.id)
  end

  def call
    return below_floor if @verdicts.count < SAMPLE_FLOOR

    klass = classify
    Result.new(readiness_class: klass, rationale: send("#{klass}_reason"))
  end

  private

  def classify
    return "deterministic" if deterministic?
    return "generatable" if generatable?

    "needs_human"
  end

  def acceptance_rate
    @acceptance_rate ||= @verdicts.where(verdict: "accepted").count.to_f / @verdicts.count
  end

  def median_edit_distance
    @median_edit_distance ||= begin
      distances = @verdicts.where.not(edit_distance: nil).order(:edit_distance).pluck(:edit_distance)
      distances.empty? ? nil : distances[distances.length / 2]
    end
  end

  def company_spread = @archetype.question_occurrences.distinct.count(:job_posting_id)

  def deterministic? = DETERMINISTIC_KINDS.include?(@archetype.question_kind) && acceptance_rate >= 0.85

  def generatable? = acceptance_rate >= 0.6 && (median_edit_distance.nil? || median_edit_distance <= 40)

  def below_floor
    Result.new(readiness_class: "needs_human",
               rationale: "Only #{@verdicts.count} verdict(s) (< #{SAMPLE_FLOOR}) -- not enough signal.")
  end

  def deterministic_reason
    "#{pct(acceptance_rate)} verbatim acceptance on a #{@archetype.question_kind} question across " \
      "#{company_spread} companies."
  end

  def generatable_reason
    "#{pct(acceptance_rate)} acceptance, median edit distance #{median_edit_distance || 0} -- " \
      "a generated draft usually lands close."
  end

  def needs_human_reason
    "#{pct(acceptance_rate)} acceptance / median edit distance #{median_edit_distance || 'n/a'} -- " \
      "proposals get materially rewritten."
  end

  def pct(ratio) = "#{(ratio * 100).round}%"
end
