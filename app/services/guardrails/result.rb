# frozen_string_literal: true

class Guardrails::Result
  attr_reader :allowed, :risk_level, :findings, :sanitized_text, :disposition

  # A plain value object -- each keyword names an independent, meaningful
  # field, not a set of related options that could collapse into one.
  # rubocop:disable-next Metrics/ParameterLists
  def initialize(allowed:, risk_level: "low", findings: [], sanitized_text: nil, disposition: "allow")
    @allowed = allowed
    @risk_level = risk_level
    @findings = findings
    @sanitized_text = sanitized_text
    @disposition = disposition
  end

  def allowed?
    @allowed
  end

  def high_risk?
    @risk_level == "high"
  end

  def blocked?
    @disposition == "block"
  end
end
