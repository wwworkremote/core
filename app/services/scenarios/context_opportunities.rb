# frozen_string_literal: true

# "Opportunities to gather more context" (ADR 010 §4): the ranked, reviewable
# "could capture this" items that fall out of a HandshakeCheck plus the
# observed-but-unmapped application fields. Each is a place where one more
# selector, one more recorded step, or one authored answer strategy would tell
# us more about this employer's flow.
#
# This is a *computed* list, not a persisted ComparisonFinding category:
# opportunities are advisory, recomputable, and carry no disposition workflow --
# unlike drift/coverage findings which are the immutable record of one run.
class Scenarios::ContextOpportunities
  Opportunity = Data.define(:kind, :reason, :rank)

  def self.call(scenario, purpose: nil, user_job_posting: nil)
    new(scenario, purpose: purpose, user_job_posting: user_job_posting).call
  end

  def initialize(scenario, purpose: nil, user_job_posting: nil)
    @scenario = scenario
    @purpose = purpose
    @user_job_posting = user_job_posting
  end

  def call
    (signature_opportunities + field_opportunities).each_with_index.map do |opportunity, index|
      opportunity.with(rank: index + 1)
    end
  end

  private

  def signature_opportunities
    missing_optional_signatures.map do |result|
      Opportunity.new(kind: result[:kind], rank: 0,
                      reason: "#{@scenario.provider} lists #{result[:kind]} as optional; this capture never saw it.")
    end
  end

  def missing_optional_signatures
    Scenarios::HandshakeCheck.call(@scenario, purpose: @purpose)
                             .select { |result| result[:status] == "optional-and-missing" }
  end

  # Observed on this application but with no ApplicationFieldMapping -- the
  # employer asks something we have no answer strategy for.
  def field_opportunities
    unmapped_observations.map do |observation|
      Opportunity.new(kind: "field:#{observation.field_key}", rank: 0,
                      reason: %(observed "#{observation.field_label}" but no answer strategy is mapped to it.))
    end
  end

  def unmapped_observations
    return [] unless @user_job_posting

    mapped_keys = @user_job_posting.application_field_mappings.distinct.pluck(:field_key)
    @user_job_posting.application_field_observations.where.not(field_key: mapped_keys)
  end
end
