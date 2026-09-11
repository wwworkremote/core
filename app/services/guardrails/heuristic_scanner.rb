# frozen_string_literal: true

class Guardrails::HeuristicScanner
  SUSPICIOUS_PATTERNS = {
    "ignore previous instructions" => 50,
    "reveal system prompt" => 50,
    "you are now system" => 50,
    "developer message" => 30,
    "act as" => 20,
    "execute command" => 40,
    "exfiltrate secrets" => 50,
    "override policy" => 40,
    "system:" => 30,
    "user:" => 30,
    "assistant:" => 30,
    "function_call" => 40,
    "BEGIN PROMPT" => 40,
    "hidden instruction" => 40
  }.freeze

  def initialize(text)
    @text = text
  end

  def call
    findings, score = scan_patterns
    findings << "High instruction density detected" if high_density?(score)

    { score: score, findings: findings }
  end

  private

  # rubocop:disable-next Metrics/MethodLength
  def scan_patterns
    findings = []
    score = 0

    SUSPICIOUS_PATTERNS.each do |pattern, weight|
      next unless @text.match?(pattern_regex(pattern))

      findings << "Matched pattern: '#{pattern}'"
      score += weight
    end

    [findings, score]
  end

  # Allow for up to 3 optional words between the keywords in the pattern
  def pattern_regex(pattern)
    words = pattern.split(/\s+/).map { |word| Regexp.escape(word) }.join('(?:\s+\w+){0,3}\s+')
    /#{words}/i
  end

  def high_density?(score)
    return false unless @text.length > 100 && score.positive?

    (score.to_f / @text.length) > 0.5
  end
end
