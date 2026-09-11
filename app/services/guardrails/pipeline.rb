# frozen_string_literal: true

class Guardrails::Pipeline
  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @raw_text = text
  end

  def call
    sanitized_text = Guardrails::Normalizer.new(@raw_text).call
    scan_result = scan(sanitized_text)
    classification = classify(scan_result)

    build_result(sanitized_text, scan_result[:findings], classification)
  end

  private

  def scan(sanitized_text)
    Guardrails::HeuristicScanner.new(sanitized_text).call
  end

  def classify(scan_result)
    Guardrails::RiskClassifier.new(scan_result[:score], scan_result[:findings]).call
  end

  # One cohesive value-object construction -- splitting it further would
  # obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def build_result(sanitized_text, findings, classification)
    Guardrails::Result.new(
      allowed: classification[:disposition] != "block",
      risk_level: classification[:risk_level],
      findings: findings,
      sanitized_text: sanitized_text,
      disposition: classification[:disposition]
    )
  end
end
