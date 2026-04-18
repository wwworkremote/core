# frozen_string_literal: true

module Guardrails
  class RiskClassifier
    def initialize(score, findings)
      @score = score
      @findings = findings
    end

    def call
      if @score >= 100
        { risk_level: 'high', disposition: 'block' }
      elsif @score >= 50
        { risk_level: 'high', disposition: 'quarantine' }
      elsif @score >= 20
        { risk_level: 'medium', disposition: 'allow' }
      else
        { risk_level: 'low', disposition: 'allow' }
      end
    end
  end
end
