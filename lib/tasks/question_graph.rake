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

  desc "AC#7 proof: duplicate observations aggregate onto one archetype, provenance intact"
  task sandbox_walkthrough: :environment do
    abort "development only" unless Rails.env.development?

    report = QuestionGraph::SandboxWalkthrough.call
    puts "question_graph:sandbox_walkthrough -> #{report.inspect}"
    abort "PROVENANCE LOST" unless report[:provenance_intact] && report[:archetypes] == 2
    puts "OK: 2 archetypes, #{report[:occurrences].sum} occurrences, per-application provenance preserved"
  end
end
