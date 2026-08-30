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
end
