# frozen_string_literal: true

# TASK-127 AC#6: an advisory report, per Question Archetype with >= N verdicts,
# of verbatim-acceptance rate + median edit distance split by strategy_source,
# plus a replay of LLM::AnswerGenerator.call against a representative occurrence
# (in a rolled-back transaction -- no DB write, no answer filled or submitted).
#
# A high acceptance rate *suggests* a readiness class; Mike sets it.
class AutomationReadiness::Eval
  SAMPLE_FLOOR = 5

  def self.call(floor: SAMPLE_FLOOR) = new(floor).call

  def initialize(floor)
    @floor = floor
  end

  def call
    { generated_at: Time.current.iso8601, sample_floor: @floor, archetypes: archetype_reports }
  end

  private

  def archetype_reports
    AnswerProposalVerdict.with_enough_evidence(@floor).filter_map do |archetype_id|
      report_for(QuestionArchetype.find(archetype_id))
    end
  end

  def report_for(archetype)
    verdicts = archetype.answer_proposal_verdicts.to_a
    { archetype_id: archetype.id, canonical_prompt: archetype.canonical_prompt, verdicts: verdicts.size,
      by_strategy: verdicts.group_by(&:strategy_source).transform_values { |group| stats(group) },
      current_replay: replay(archetype) }
  end

  def stats(verdicts)
    { acceptance_rate: ratio(verdicts.count { |v| v.verdict == "accepted" }, verdicts.size),
      median_edit_distance: median(verdicts.filter_map(&:edit_distance)) }
  end

  def ratio(hits, total) = total.zero? ? nil : (hits.to_f / total).round(3)

  def median(values)
    return nil if values.empty?

    values.sort[values.length / 2]
  end

  # What the current rule/template/prompt set produces now -- rolled back so
  # nothing is written and no answer is applied.
  def replay(archetype)
    occurrence = archetype.question_occurrences.where(source_kind: "manual_question").first
    return "no manual occurrence to replay" unless occurrence&.job_posting

    replay_answer(occurrence)
  end

  def replay_answer(occurrence)
    result = rolled_back_replay(occurrence)
    result[:success] ? "strategy=#{result[:source]}" : "unavailable (#{result[:error]})"
  end

  def rolled_back_replay(occurrence)
    @replay_result = nil
    ActiveRecord::Base.transaction { capture_replay(occurrence) }
    @replay_result
  end

  def capture_replay(occurrence)
    @replay_result = LLM::AnswerGenerator.call(replay_question(occurrence))
    raise ActiveRecord::Rollback
  end

  def replay_question(occurrence)
    occurrence.job_posting.application_questions.create!(user: occurrence.user, question_text: occurrence.raw_prompt)
  end
end
