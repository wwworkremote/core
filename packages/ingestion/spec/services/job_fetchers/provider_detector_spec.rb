# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobFetchers::ProviderDetector do
  describe ".call" do
    it "matches a known ATS/board domain to its provider key" do
      expect(described_class.call("https://www.dice.com/jobs/detail/123")).to eq("dice")
      expect(described_class.call("https://boards.greenhouse.io/acme/jobs/1")).to eq("greenhouse")
    end

    it "maps weworkremotely.com to the wwr selector key" do
      expect(described_class.call("https://weworkremotely.com/remote-jobs/1")).to eq("wwr")
    end

    it "returns generic for an unrecognized domain" do
      expect(described_class.call("https://example.com/jobs/1")).to eq("generic")
    end

    it "returns generic for a blank url" do
      expect(described_class.call(nil)).to eq("generic")
      expect(described_class.call("")).to eq("generic")
    end
  end
end
