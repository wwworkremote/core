# frozen_string_literal: true

class Guardrails::Pipeline
  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @raw_text = text
  end

  def call
    # 1. Normalize
    sanitized_text = Guardrails::Normalizer.new(@raw_text).call

    # 2. Heuristic Scan
    scan_result = Guardrails::HeuristicScanner.new(sanitized_text).call
    score = scan_result[:score]
    findings = scan_result[:findings]

    # 3. Risk Classification
    classification = Guardrails::RiskClassifier.new(score, findings).call

    Guardrails::Result.new(
      allowed: classification[:disposition] != 'block',
      risk_level: classification[:risk_level],
      findings: findings,
      sanitized_text: sanitized_text,
      disposition: classification[:disposition]
    )
  end
end
