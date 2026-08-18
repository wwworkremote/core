# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::AnswerGenerator::CannedAnswers do
  describe ".match" do
    let(:profile) {
      create(:career_profile, location_info: { "display" => "Chicago, IL" },
                              contact_info: { "github" => { "url" => "https://github.com/just3ws" },
                                              "linkedin" => { "url" => "https://linkedin.com/in/just3ws" } })
    }

    it "returns nil when the profile is nil" do
      expect(described_class.match("How many years of experience?", nil)).to be_nil
    end

    it "returns nil for a question with no matching canned pattern" do
      expect(described_class.match("Why do you want to work here?", profile)).to be_nil
    end

    context "years of experience" do
      before do
        create(:work_experience, career_profile: profile, start_date: 10.years.ago.to_date,
                                 end_date: 8.years.ago.to_date)
        create(:work_experience, career_profile: profile, start_date: 5.years.ago.to_date, end_date: nil)
      end

      it "computes years from earliest start to latest end (or today), regardless of question phrasing" do
        expect(described_class.match("How many years of experience do you have?", profile)).to eq("10 years")
        expect(described_class.match("Whats your total years of professional experience?", profile)).to eq("10 years")
      end

      it "returns nil when there are no work experiences to compute from" do
        empty_profile = create(:career_profile)
        expect(described_class.match("years of experience?", empty_profile)).to be_nil
      end
    end

    context "location" do
      it "matches multiple natural phrasings" do
        expect(described_class.match("Where are you currently located?", profile)).to eq("Chicago, IL")
        expect(described_class.match("What is your current location?", profile)).to eq("Chicago, IL")
        expect(described_class.match("Are you based in the US?", profile)).to eq("Chicago, IL")
      end

      it "returns nil when location_info is blank" do
        blank_profile = create(:career_profile, location_info: nil)
        expect(described_class.match("your location?", blank_profile)).to be_nil
      end
    end

    context "github/portfolio" do
      it "returns the contact_info github url" do
        expect(described_class.match("Share your GitHub profile", profile)).to eq("https://github.com/just3ws")
        expect(described_class.match("Do you have a portfolio?", profile)).to eq("https://github.com/just3ws")
      end

      it "falls back to career_profile.github_url when contact_info has none" do
        fallback_profile = create(:career_profile, contact_info: nil, github_url: "https://github.com/fallback")
        expect(described_class.match("github link?", fallback_profile)).to eq("https://github.com/fallback")
      end
    end

    context "linkedin" do
      it "returns the contact_info linkedin url" do
        expect(described_class.match("What's your LinkedIn?", profile)).to eq("https://linkedin.com/in/just3ws")
      end
    end
  end
end
