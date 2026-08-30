# frozen_string_literal: true

# TASK-113 AC#6: explicit backfill of existing question data into the
# knowledge graph. Idempotent -- safe to re-run. Logic lives in
# QuestionGraph::Backfill (rake tasks must not define methods).
namespace :question_graph do
  desc "Backfill QuestionOccurrences + seed AnswerStrategies from existing data"
  task backfill: :environment do
    result = QuestionGraph::Backfill.call
    puts "question_graph:backfill -> #{result[:occurrences]} occurrences, " \
         "#{result[:strategies]} answer strategies, #{QuestionArchetype.active.count} archetypes"
  end
end
