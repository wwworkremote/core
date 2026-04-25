# frozen_string_literal: true

class Guardrails::HeuristicScanner
  SUSPICIOUS_PATTERNS = {
    'ignore previous instructions' => 50,
    'reveal system prompt' => 50,
    'you are now system' => 50,
    'developer message' => 30,
    'act as' => 20,
    'execute command' => 40,
    'exfiltrate secrets' => 50,
    'override policy' => 40,
    'system:' => 30,
    'user:' => 30,
    'assistant:' => 30,
    'function_call' => 40,
    'BEGIN PROMPT' => 40,
    'hidden instruction' => 40
  }.freeze

  def initialize(text)
    @text = text
  end

  def call
    findings = []
    score = 0

    SUSPICIOUS_PATTERNS.each do |pattern, weight|
      # Allow for up to 3 optional words between the keywords in the pattern
      regex_pattern = pattern.split(/\s+/).map { |word| Regexp.escape(word) }.join('(?:\s+\w+){0,3}\s+')
      if @text.match?(/#{regex_pattern}/i)
        findings << "Matched pattern: '#{pattern}'"
        score += weight
      end
    end

    # Density check
    if @text.length > 100 && score.positive?
      density = score.to_f / @text.length
      findings << 'High instruction density detected' if density > 0.5
    end

    { score: score, findings: findings }
  end
end
