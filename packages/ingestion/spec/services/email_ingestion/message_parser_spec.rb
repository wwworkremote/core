# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::MessageParser do
  let(:file_path) { Rails.root.join("spec/fixtures/emails/indeed.eml") }
  let(:parser) { described_class.new(file_path) }

  describe "#call" do
    it "parses the email correctly" do
      result = parser.call
      expect(result[:message_id]).to eq("1234567890@indeed.com")
      expect(result[:from]).to eq("indeed@indeed.com")
      expect(result[:subject]).to eq("New jobs at Indeed")
      expect(result[:date]).to be_a(DateTime)
      expect(result[:html_body]).to include("Software Engineer at TechCorp")
    end
  end
end
