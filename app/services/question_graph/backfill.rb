# frozen_string_literal: true

# TASK-113 AC#6: one-time (re-runnable) backfill of the question knowledge
# graph from existing data. QuestionOccurrences::Record handles occurrence
# dedupe + archetype assignment; this adds the answer-strategy seeding.
class QuestionGraph::Backfill
  def self.call = new.call

  def call
    { occurrences: backfill_occurrences, strategies: seed_strategies }
  end

  private

  def backfill_occurrences
    sources = ApplicationFieldObservation.order(:id).to_a + ApplicationQuestion.order(:id).to_a
    sources.count { |record| QuestionOccurrences::Record.call(record) }
  end

  def seed_strategies
    from_templates + from_submitted_answers
  end

  def from_templates
    ApplicationAnswerTemplate.find_each.count { |template| seed_from_template(template) }
  end

  def from_submitted_answers
    submitted_questions.count { |question| seed_from_submitted(question) }
  end

  def submitted_questions
    ApplicationQuestion.where(answer_source: "submitted").where.not(answer_text: [nil, ""])
  end

  # rubocop:disable Metrics/MethodLength
  def seed_from_template(template)
    archetype = QuestionArchetype.active.find_by(canonical_prompt: template.normalized_prompt)
    return unless archetype

    source = template.source == "manual" ? "authored" : template.source
    record_strategy(archetype, template.answer, source: source, sophistication: "authored",
                                                persona_id: template.persona_id,
                                                provenance: { "application_answer_template_id" => template.id })
  end

  def seed_from_submitted(question)
    occurrence = QuestionOccurrence.find_by(job_posting_id: question.job_posting_id, user_id: question.user_id,
                                            source_kind: "manual_question")
    archetype = occurrence&.question_archetype
    return unless archetype

    record_strategy(archetype, question.answer_text, source: "submitted", sophistication: "authored",
                                                     provenance: { "application_question_id" => question.id })
  end
  # rubocop:enable Metrics/MethodLength

  # Returns the created AnswerStrategy, or nil if an equivalent one exists.
  def record_strategy(archetype, answer, **attrs)
    return if archetype.answer_strategies.exists?(answer_text: answer, source: attrs[:source])

    archetype.answer_strategies.create!(answer_text: answer, **attrs)
  end
end
