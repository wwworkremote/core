# frozen_string_literal: true

# Read-model for the question-graph index (TASK-113 AC#4): the most common
# archetypes and their spread across the corpus, plus answer-strategy
# coverage gaps. Relational aggregates -- no graph database (ADR 008 delivery
# boundary).
class QuestionGraph::Overview
  Row = Data.define(:archetype, :occurrences, :companies, :providers, :strategies)
  COUNTS_SQL = "count(*), count(distinct job_posting_id), count(distinct provider)"

  def self.call(limit: 50) = new(limit).call

  def initialize(limit)
    @limit = limit
  end

  def call
    { rows: rows, coverage_gaps: coverage_gaps, totals: totals }
  end

  private

  def rows
    ranked_archetypes.map { |archetype| build_row(archetype) }
  end

  def ranked_archetypes
    QuestionArchetype.active.left_joins(:question_occurrences).group(:id)
                     .order(Arel.sql("count(question_occurrences.id) desc")).limit(@limit)
  end

  def build_row(archetype)
    occ, companies, providers = archetype.question_occurrences.pick(Arel.sql(COUNTS_SQL))
    Row.new(archetype: archetype, occurrences: occ, companies: companies, providers: providers,
            strategies: archetype.answer_strategies.active.count)
  end

  # Active archetypes seen more than once with no enabled answer strategy.
  def coverage_gaps
    QuestionArchetype.active.where.missing(:answer_strategies)
                     .select { |archetype| archetype.question_occurrences.many? }
  end

  def totals
    { archetypes: QuestionArchetype.active.count, occurrences: QuestionOccurrence.count,
      strategies: AnswerStrategy.active.count }
  end
end
