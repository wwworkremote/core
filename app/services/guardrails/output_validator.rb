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
    findings = []

    # 1. Pattern check for prompt injection leakage
    FORBIDDEN_PATTERNS.each do |pattern|
      findings << "Forbidden pattern detected in output: #{pattern.source}" if @output.match?(pattern)
    end

    # 2. JSON validation if schema provided
    if @schema
      begin
        parsed = JSON.parse(@output.match(/\{.*\}/m)&.[](0) || "")
        # Basic structural check for this implementation
        @schema.each do |key, type|
          findings << "Schema violation: expected #{key} to be #{type}" unless parsed[key].is_a?(type)
        end
      rescue StandardError => e
        findings << "JSON parse/validation error: #{e.message}"
      end
    end

    { valid: findings.empty?, findings: findings }
  end
end
