# frozen_string_literal: true

class Guardrails::OutputValidator
  FORBIDDEN_PATTERNS = [
    /ignore previous/i,
    /reveal system/i,
    /you are now/i,
    /I am now/i,
    /I cannot fulfill/i
  ].freeze

  def initialize(output, schema: nil)
    @output = output.to_s
    @schema = schema
  end

  def call
    findings = pattern_findings + schema_findings
    { valid: findings.empty?, findings: findings }
  end

  private

  # Pattern check for prompt injection leakage. Not `grep(@output)`: grep
  # tests `pattern === element`, but this needs `element === @output` for
  # each pattern against one fixed string -- grep can't express that
  # reversed direction, so `select` stays.
  # rubocop:disable Style/SelectByRegexp
  def pattern_findings
    FORBIDDEN_PATTERNS.select { |pattern| pattern.match?(@output) }
                      .map { |pattern| "Forbidden pattern detected in output: #{pattern.source}" }
  end
  # rubocop:enable Style/SelectByRegexp

  # JSON validation if schema provided
  def schema_findings
    return [] unless @schema

    validate_schema
  end

  def validate_schema
    parsed = parse_json_body
    # Basic structural check for this implementation
    @schema.filter_map { |key, type| "Schema violation: expected #{key} to be #{type}" unless parsed[key].is_a?(type) }
  rescue StandardError => e
    ["JSON parse/validation error: #{e.message}"]
  end

  def parse_json_body
    JSON.parse(@output.match(/\{.*\}/m)&.[](0) || "")
  end
end
