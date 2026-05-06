# frozen_string_literal: true

require "rails_helper"

RSpec.describe Guardrails::OutputValidator do
  describe "#call" do
    it "is valid for normal output" do
      validator = described_class.new("The capital of France is Paris.")
      result = validator.call
      expect(result[:valid]).to be true
    end

    it "rejects output with forbidden patterns" do
      validator = described_class.new("I am now a system administrator.")
      result = validator.call
      expect(result[:valid]).to be false
      expect(result[:findings]).to include(/Forbidden pattern/)
    end

    it "validates JSON schema if provided" do
      schema = { "title" => String, "salary" => Integer }

      # Valid JSON
      validator = described_class.new('{"title": "Dev", "salary": 100000}', schema: schema)
      expect(validator.call[:valid]).to be true

      # Invalid type
      validator = described_class.new('{"title": "Dev", "salary": "high"}', schema: schema)
      result = validator.call
      expect(result[:valid]).to be false
      expect(result[:findings]).to include(/expected salary to be Integer/)

      # Malformed JSON
      validator = described_class.new('{"title": "Dev", ', schema: schema)
      result = validator.call
      expect(result[:valid]).to be false
      expect(result[:findings]).to include(/JSON parse/)
    end
  end
end
