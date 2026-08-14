# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPosting::StatusWorkflow do
  describe "#restore!" do
    it "restores a purged posting to none" do
      posting = create(:job_posting, status: "purged")

      posting.restore!

      expect(posting.reload.status).to eq("none")
    end

    it "restores an ignored posting to none" do
      # Covers the Geo::CommuteZone remote-key bug: a posting could be
      # auto-ignored despite being remote, and needed a way back once the
      # underlying classification was fixed.
      posting = create(:job_posting, status: "ignored")

      posting.restore!

      expect(posting.reload.status).to eq("none")
    end

    it "refuses to restore a posting in an unrelated state" do
      posting = create(:job_posting, status: "favorited")

      expect { posting.restore! }.to raise_error(AASM::InvalidTransition)
    end
  end
end
