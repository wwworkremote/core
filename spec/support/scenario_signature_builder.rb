# frozen_string_literal: true

# Builds a Scenario whose signatures are recorded in the given order, so
# ReferenceDiff / Coverage / DriftAnalysis specs can express an ordered marker
# sequence as a plain list of [kind, value] pairs.
module ScenarioSignatureBuilder
  def scenario_with(pairs, provider: "greenhouse")
    create(:scenario, provider: provider).tap do |scenario|
      pairs.each_with_index { |(kind, value), index| add_signature(scenario, kind, value, index) }
    end
  end

  def add_signature(scenario, kind, value, index)
    create(:scenario_signature, scenario: scenario, kind: kind, value: value || "x",
                                first_observed_at: 10.minutes.ago + index.seconds)
  end
end

RSpec.configure { |config| config.include ScenarioSignatureBuilder }
