# frozen_string_literal: true

# "Opportunities to gather more context" (ADR 010 §4): the ranked, reviewable
# "could capture this" items that fall out of a HandshakeCheck. A signature a
# provider lists as optional but that this capture never observed is a place
# where one more selector or one more recorded step would tell us more.
#
# This is a *computed* list, not a persisted ComparisonFinding category:
# opportunities are advisory, recomputable from the scenario, and carry no
# disposition workflow -- unlike drift/coverage findings which are the
# immutable record of one comparison run.
#
# NOTE: "un-mapped observed fields" (ADR 010 §4) are not yet included -- that
# needs the ApplicationFieldMapping join, which is UserJobPosting-scoped, not
# on the Scenario. Tracked as a follow-up.
class Scenarios::ContextOpportunities
  Opportunity = Data.define(:kind, :reason, :rank)

  def self.call(scenario, purpose: nil)
    new(scenario, purpose: purpose).call
  end

  def initialize(scenario, purpose: nil)
    @scenario = scenario
    @purpose = purpose
  end

  def call
    missing_optional_signatures.each_with_index.map do |result, index|
      Opportunity.new(kind: result[:kind], rank: index + 1,
                      reason: "#{@scenario.provider} lists #{result[:kind]} as optional; this capture never saw it.")
    end
  end

  private

  def missing_optional_signatures
    Scenarios::HandshakeCheck.call(@scenario, purpose: @purpose)
                             .select { |result| result[:status] == "optional-and-missing" }
  end
end
