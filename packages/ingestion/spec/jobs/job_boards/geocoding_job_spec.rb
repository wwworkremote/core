# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::GeocodingJob do
  let(:job_posting) { create(:job_posting, location: "Worldwide") }

  describe "#perform" do
    it "geocodes and updates latitude/longitude/country_code" do
      described_class.perform_now(job_posting.id)

      job_posting.reload
      expect(job_posting.latitude).to eq(0.0)
      expect(job_posting.longitude).to eq(0.0)
      expect(job_posting.country_code).to eq("WW")
    end

    it "does nothing when the geocoding source is locked" do
      Rails.cache.write("api_guard:geocoding:locked_until", 1.hour.from_now)

      described_class.perform_now(job_posting.id)

      expect(job_posting.reload.latitude).to be_nil
    end

    it "does nothing when the job posting does not exist" do
      expect { described_class.perform_now(0) }.not_to raise_error
    end

    it "does nothing when the job posting has no location" do
      job_posting.update!(location: nil)

      described_class.perform_now(job_posting.id)

      expect(job_posting.reload.latitude).to be_nil
    end

    it "does nothing for an expired job posting unless forced" do
      job_posting.expire!

      described_class.perform_now(job_posting.id)

      expect(job_posting.reload.latitude).to be_nil
    end

    it "geocodes an expired job posting when forced" do
      job_posting.expire!

      described_class.perform_now(job_posting.id, force: true)

      expect(job_posting.reload.latitude).to eq(0.0)
    end

    it "does nothing (but does not error) when Geocoder finds no results" do
      job_posting.update!(location: "Nowhere, Unmapped")

      expect { described_class.perform_now(job_posting.id) }.not_to raise_error
      expect(job_posting.reload.latitude).to be_nil
    end

    it "locks the geocoding source on Geocoder::OverQueryLimitError" do
      allow(Geocoder).to receive(:search).and_raise(Geocoder::OverQueryLimitError)

      described_class.perform_now(job_posting.id)

      locked_until = Rails.cache.read("api_guard:geocoding:locked_until")
      expect(locked_until).to be_present
    end

    it "locks the geocoding source on a generic 429 error" do
      allow(Geocoder).to receive(:search).and_raise(StandardError, "429 Too Many Requests")

      described_class.perform_now(job_posting.id)

      expect(Rails.cache.read("api_guard:geocoding:locked_until")).to be_present
    end

    it "logs and does not lock on other StandardErrors" do
      allow(Geocoder).to receive(:search).and_raise(StandardError, "connection reset")

      described_class.perform_now(job_posting.id)

      expect(Rails.cache.read("api_guard:geocoding:locked_until")).to be_nil
    end
  end
end
