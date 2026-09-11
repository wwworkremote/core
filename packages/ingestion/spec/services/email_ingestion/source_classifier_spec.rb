# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmailIngestion::SourceClassifier do
  let(:parsed_email) { { from: "indeed@indeed.com", subject: "New jobs" } }
  let(:classifier) { described_class.new(parsed_email) }

  describe "#call" do
    it "identifies indeed from email address" do
      expect(classifier.call).to eq("indeed")
    end

    it "identifies linkedin from email address" do
      parsed_email[:from] = "jobs-listings@linkedin.com"
      expect(classifier.call).to eq("linkedin")
    end

    it "identifies adzuna from email address" do
      parsed_email[:from] = "alerts@adzuna.com"
      expect(classifier.call).to eq("adzuna")
    end

    it "identifies indeed from subject if email unknown" do
      parsed_email[:from] = "unknown@example.com"
      parsed_email[:subject] = "Your Indeed Job Alert"
      expect(classifier.call).to eq("indeed")
    end

    it "returns unknown for unrecognized emails" do
      parsed_email[:from] = "spam@example.com"
      parsed_email[:subject] = "Buy more stuff"
      expect(classifier.call).to eq("unknown")
    end
  end
end
