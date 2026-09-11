# frozen_string_literal: true

require "rails_helper"

RSpec.describe Guardrails::Normalizer do
  describe "#call" do
    it "removes invalid UTF-8 characters" do
      text = "Hello \xAD World".dup.force_encoding("UTF-8")
      expect(described_class.new(text).call).to eq("Hello World")
    end

    it "replaces null bytes with spaces" do
      text = "Zero\u0000Byte"
      expect(described_class.new(text).call).to eq("Zero Byte")
    end

    it "collapses multiple spaces and tabs" do
      text = "Too    many \t  spaces"
      expect(described_class.new(text).call).to eq("Too many spaces")
    end

    it "collapses pathological newlines" do
      text = "Line 1\n\n\n\nLine 2"
      expect(described_class.new(text).call).to eq("Line 1\n\nLine 2")
    end

    it "strips leading and trailing whitespace" do
      text = "  spaced  "
      expect(described_class.new(text).call).to eq("spaced")
    end

    it "returns empty string for blank input" do
      expect(described_class.new(nil).call).to eq("")
      expect(described_class.new("").call).to eq("")
      expect(described_class.new("   ").call).to eq("")
    end
  end
end
