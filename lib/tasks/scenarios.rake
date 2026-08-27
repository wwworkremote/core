# frozen_string_literal: true

namespace :scenarios do
  desc "Preview a candidate Scenario against the provider reference; set PROMOTE=1 to explicitly replace it"
  task :reference_diff, [:scenario_token] => :environment do |_, args|
    candidate = Scenario.find_by!(scenario_token: args.fetch(:scenario_token))
    reference = ReferenceScenario.find_by(provider: candidate.provider)&.scenario
    diff = Scenarios::ReferenceDiff.call(candidate, reference: reference)

    puts JSON.pretty_generate(diff)
    next unless ENV["PROMOTE"] == "1"

    Scenarios::PromoteReference.call(candidate)
    puts "Promoted #{candidate.scenario_token} as #{candidate.provider} reference."
  end
end
