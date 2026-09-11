# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPostingsHelper do
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

  describe "#version_changes_summary" do
    let(:job) { create(:job_posting, title: "Original Title", status: "none") }

    it "summarizes what changed, in human-readable form, excluding timestamps" do
      job.update!(title: "Updated Title")
      version = job.versions.last

      summary = helper.version_changes_summary(version)

      expect(summary).to eq(["Title: Original Title → Updated Title"])
    end

    it "returns nil when the version has an empty changeset" do
      version = job.versions.last
      allow(version).to receive(:changeset).and_return({})

      expect(helper.version_changes_summary(version)).to be_nil
    end

    it "returns nil rather than raising when changeset itself is nil (real historical versions predate tracking)" do
      version = job.versions.last
      allow(version).to receive(:changeset).and_return(nil)

      expect(helper.version_changes_summary(version)).to be_nil
    end

    it "summarizes non-scalar values without dumping raw content" do
      job.update!(data: job.data.merge("marker" => "x"))
      version = job.versions.last

      summary = helper.version_changes_summary(version)

      expect(summary).to include("Data: changed → changed")
    end
  end
end
