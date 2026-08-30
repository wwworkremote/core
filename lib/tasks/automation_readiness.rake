# frozen_string_literal: true

# TASK-127: the automation-readiness corpus + eval harness. Both write only to
# the git-ignored data/datalake/corpus/ directory; the eval never writes to the
# database and never fills or submits an answer.
namespace :automation_readiness do
  desc "Export per-archetype verdict corpus JSONL to data/datalake/corpus/"
  task corpus: :environment do
    written = AutomationReadiness::CorpusExporter.call
    puts "automation_readiness:corpus -> #{written} verdict lines across " \
         "#{Dir[AutomationReadiness::CorpusExporter::DIR.join('*.jsonl')].size} archetype files"
  end

  desc "Advisory eval: acceptance rate + median edit distance by strategy, per archetype (no DB write)"
  task eval: :environment do
    report = AutomationReadiness::Eval.call
    path = AutomationReadiness::CorpusExporter::DIR.join("eval_report.json")
    FileUtils.mkdir_p(path.dirname)
    path.write(JSON.pretty_generate(report))
    puts "automation_readiness:eval -> #{report[:archetypes].size} archetype(s) over floor; report at #{path}"
  end
end
