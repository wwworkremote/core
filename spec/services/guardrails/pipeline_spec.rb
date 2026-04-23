# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe Guardrails::Pipeline do
  let(:test_cases) { YAML.load_file(Rails.root.join('spec/fixtures/guardrails/red_team/test_cases.yml')) }

  describe '.call' do
    it 'correctly classifies red-team test cases' do
      test_cases.each do |tc|
        result = described_class.call(tc['text'])

        expect(result.risk_level).to eq(tc['expected_risk']), "Case '#{tc['name']}' expected risk #{tc['expected_risk']} but got #{result.risk_level}"
        expect(result.disposition).to eq(tc['expected_disposition']), "Case '#{tc['name']}' expected disposition #{tc['expected_disposition']} but got #{result.disposition}"
      end
    end

    it 'sanitizes input' do
      text = "Hello\u0000World\n\n\n\n\n\n\nTest"
      result = described_class.call(text)
      expect(result.sanitized_text).to include('Hello World')
      expect(result.sanitized_text).to include("\n\nTest")
    end
  end
end
