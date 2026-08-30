# frozen_string_literal: true

# TASK-126: prove a guided session produces a datalake bundle + manifest.
namespace :datalake do
  desc "AC#8 proof: a guided session yields a manifest with one asset set per event + a gap"
  task sandbox_walkthrough: :environment do
    abort "development only" unless Rails.env.development?

    report = Datalake::SandboxWalkthrough.call
    puts "datalake:sandbox_walkthrough -> #{report.inspect}"
    abort "MANIFEST INCOMPLETE" unless report[:assets] == 3 && report[:gaps] == 1 && report[:every_event_pointed]
    puts "OK: 3 DOM assets, 1 gap, every event points back at its manifest entries"
  end
end
