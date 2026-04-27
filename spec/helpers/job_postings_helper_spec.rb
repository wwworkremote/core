# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPostingsHelper, type: :helper do
  describe "#safe_job_url" do
    it "returns the url if valid" do
      url = "https://example.com"
      expect(helper.safe_job_url(url)).to eq(url)
    end

    it "returns # if blank" do
      expect(helper.safe_job_url("")).to eq("#")
      expect(helper.safe_job_url(nil)).to eq("#")
    end

    it "returns # for invalid schemes" do
      expect(helper.safe_job_url("javascript:alert(1)")).to eq("#")
    end

    it "returns # for malformed URLs" do
      expect(helper.safe_job_url("not a url")).to eq("#")
    end
  end
end
