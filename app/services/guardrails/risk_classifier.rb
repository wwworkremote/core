# frozen_string_literal: true

class Guardrails::RiskClassifier
  def initialize(score, findings)
    @score = score
    @findings = findings
  end

  def call
    { risk_level: risk_level, disposition: disposition }
  end

  private

  def risk_level
    return "high" if @score >= 50
    return "medium" if @score >= 20

    "low"
  end

  def disposition
    return "block" if @score >= 100
    return "quarantine" if @score >= 50

    "allow"
  end
end
