# frozen_string_literal: true

class Scenarios::PromoteReference
  def self.call(scenario)
    new(scenario).call
  end

  def initialize(scenario)
    @scenario = scenario
  end

  # rubocop:disable-next Metrics/MethodLength -- one transaction is the explicit write seam.
  def call
    ReferenceScenario.transaction do
      reference = ReferenceScenario.find_or_initialize_by(provider: @scenario.provider)
      reference.scenario = @scenario
      reference.save!
      reference
    end
  end
end
