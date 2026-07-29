# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::QualityFilter do
  let(:user) { create(:user, preferred_countries: %w[US]) }
  let(:job_posting) do
    create(:job_posting, title: "Staff Ruby Engineer", country_code: "US", body: "x" * 60)
  end

  describe "#useful?" do
    it "accepts a well-formed job matching the user's preferred country" do
      expect(described_class.new(job_posting, user: user).useful?).to be true
    end

    it "rejects a blank title" do
      job_posting.title = ""
      expect(described_class.new(job_posting, user: user).useful?).to be false
    end

    it "rejects a banned title, case-insensitively" do
      job_posting.title = "sign in"
      expect(described_class.new(job_posting, user: user).useful?).to be false
    end

    it "rejects a title shorter than 3 characters" do
      job_posting.title = "QA"
      expect(described_class.new(job_posting, user: user).useful?).to be false
    end

    it "rejects a country_code outside the user's preferred countries" do
      job_posting.country_code = "DE"
      expect(described_class.new(job_posting, user: user).useful?).to be false
    end

    it "accepts a job with no country_code regardless of preferred countries" do
      job_posting.country_code = nil
      expect(described_class.new(job_posting, user: user).useful?).to be true
    end

    it "does not filter junior/intern titles (no seniority filtering implemented yet)" do
      job_posting.title = "Junior Ruby Engineer"
      expect(described_class.new(job_posting, user: user).useful?).to be true
    end

    it "rejects a body shorter than 50 characters" do
      job_posting.body = "too short"
      expect(described_class.new(job_posting, user: user).useful?).to be false
    end

    it "rejects a blank body" do
      job_posting.body = ""
      expect(described_class.new(job_posting, user: user).useful?).to be false
    end

    it "defaults to the primary user when none is given" do
      create(:user, preferred_countries: %w[US])

      expect(described_class.new(job_posting).useful?).to be true
    end
  end
end
