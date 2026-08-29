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

  desc "Rebuild the Greenhouse sandbox Reference Scenario from a full execution guided session (ADR 009, TASK-118)"
  task build_sandbox_reference: :environment do
    abort "Refusing: sandbox reference is dev/test only (Rails.env.local?)." unless Rails.env.local?

    scenario = Scenarios::SandboxReferenceWalkthrough.call
    puts "Promoted #{scenario.scenario_token} as the greenhouse reference."
    scenario.scenario_signatures.order(:first_observed_at, :id).each do |signature|
      puts "  #{signature.kind} = #{signature.value}"
    end
  end
end
