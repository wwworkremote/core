# frozen_string_literal: true

# TASK-126: prove a guided session produces a datalake bundle + manifest.
namespace :datalake do
  desc "AC#8 / TASK-134 AC#4 proof: execution bundle carries har + full-page screenshot, research bundle the light set"
  task sandbox_walkthrough: :environment do
    abort "development only" unless Rails.env.development?

    report = Datalake::SandboxWalkthrough.call
    puts "datalake:sandbox_walkthrough -> #{report.inspect}"
    abort "EXECUTION BUNDLE INCOMPLETE" unless report[:execution][:asset_types] == %w[dom har screenshot] &&
                                               report[:execution][:gaps] == 1 &&
                                               report[:execution][:every_event_pointed]
    abort "RESEARCH BUNDLE INCOMPLETE" unless report[:research][:asset_types] == %w[dom screenshot] &&
                                              report[:research][:gaps].zero? &&
                                              report[:research][:every_event_pointed]
    puts "OK: execution bundle has har + full-page screenshot + 1 detach gap; research bundle is dom + screenshot only"
  end

  # ADR 010 curation report + prune. Dry run by default -- reads the report,
  # then re-run with PRUNE=1 to delete the prune_first / prune_eligible /
  # orphan bundles (the raw PII-bearing layer, value already extracted).
  desc "Curation report for the datalake raw layer; PRUNE=1 to actually delete eligible bundles"
  task prune: :environment do
    abort "local only" unless Rails.env.local?

    prune = ENV["PRUNE"] == "1"
    rows = Datalake::Prune.call(prune: prune)
    rows.group_by(&:verdict).sort.each do |verdict, group|
      mb = (group.sum(&:bytes).to_f / 1.megabyte).round(1)
      puts "#{verdict} (#{group.size} bundle(s), #{mb} MB)"
      group.each { |row| puts "  #{row.session_token}  #{row.assets} asset(s)  -- #{row.reason}" }
    end
    puts prune ? "PRUNED #{rows.count { |r|
      Datalake::Prune::PRUNABLE.include?(r.verdict)
    }} bundle(s)" : "dry run -- re-run with PRUNE=1 to delete the prune_first / prune_eligible / orphan bundles"
  end
end
