# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::QualityFilter do
  let(:user) { create(:user, preferred_countries: ["US"]) }
  let(:job_posting) { build(:job_posting, title: "Senior Ruby Engineer", body: "A" * 60, country_code: "US") }
  let(:filter) { described_class.new(job_posting, user: user) }

  describe "#useful?" do
    it "is true for a normal, well-formed Engineering posting" do
      expect(filter.useful?).to be true
    end

    it "is false when the title is blank" do
      job_posting.title = ""
      expect(filter.useful?).to be false
    end

    it "is false for a banned navigation/UI title" do
      job_posting.title = "Sign In"
      expect(filter.useful?).to be false
    end

    it "is false when the title is shorter than 3 characters" do
      job_posting.title = "QA"
      expect(filter.useful?).to be false
    end

    it "is false when the posting's country isn't in the user's preferred countries" do
      job_posting.country_code = "DE"
      expect(filter.useful?).to be false
    end

    it "is true when country_code is blank, regardless of preferred_countries" do
      job_posting.country_code = nil
      expect(filter.useful?).to be true
    end

    it "is false when the body is blank" do
      job_posting.body = ""
      expect(filter.useful?).to be false
    end

    it "is false when the body is shorter than 50 characters" do
      job_posting.body = "Too short."
      expect(filter.useful?).to be false
    end

    context "results-excluded source (TASK-69.2)" do
      # Origin <-> JobBoards::Source have no FK -- only a shared name,
      # established by JobBoards::Syncer#resolve_dashboard_source.
      it "is false when the source's Origin name matches an excluded JobBoards::Source" do
        create(:job_boards_source, name: "Arbeitnow", excluded_from_results: true)
        job_posting.source = create(:source, origin: Origin.create!(name: "Arbeitnow"))

        expect(filter.useful?).to be false
      end

      it "is true when the matching JobBoards::Source is not excluded" do
        create(:job_boards_source, name: "Arbeitnow", excluded_from_results: false)
        job_posting.source = create(:source, origin: Origin.create!(name: "Arbeitnow"))

        expect(filter.useful?).to be true
      end

      it "is true when no JobBoards::Source matches the origin name" do
        job_posting.source = create(:source, origin: Origin.create!(name: "Unregistered Board"))

        expect(filter.useful?).to be true
      end

      it "is true when the posting has no source at all" do
        job_posting.source = nil

        expect(filter.useful?).to be true
      end
    end

    context "non-Engineering title keyword matching" do
      described_class::NON_ENGINEERING_TITLE_KEYWORDS.each do |keyword|
        it "is false for a title containing #{keyword.inspect}" do
          job_posting.title = "Senior #{keyword}"
          expect(filter.useful?).to be false
        end
      end

      it "matches case-insensitively" do
        job_posting.title = "senior account executive"
        expect(filter.useful?).to be false
      end

      it "does not reject engineering-adjacent hybrid titles like Sales Engineer" do
        job_posting.title = "Sales Engineer"
        expect(filter.useful?).to be true
      end

      it "does not reject Solutions Engineer" do
        job_posting.title = "Solutions Engineer"
        expect(filter.useful?).to be true
      end
    end
  end
end
