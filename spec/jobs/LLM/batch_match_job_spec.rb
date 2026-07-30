# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::BatchMatchJob do
  let!(:user) { create(:user, email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) }
  let!(:ruby_job) { create(:job_posting, title: "Senior Ruby Engineer") }
  let!(:other_job) { create(:job_posting, title: "Java Developer") }

  before do
    create(:career_profile, user: user, resume_text: "I am a Ruby expert.")
    allow(LLM::ProfileMatcher).to receive(:call)
  end

  describe "#perform" do
    it "processes relevant job postings" do
      described_class.perform_now
      expect(LLM::ProfileMatcher).to have_received(:call).with(user, ruby_job)
      expect(LLM::ProfileMatcher).not_to have_received(:call).with(user, other_job)
    end

    it "skips already analyzed postings" do
      create(:user_job_posting, user: user, job_posting: ruby_job)
      described_class.perform_now
      expect(LLM::ProfileMatcher).not_to have_received(:call).with(user, ruby_job)
    end

    it "respects the limit parameter" do
      create_list(:job_posting, 5, title: "Ruby Dev")
      described_class.perform_now(limit: 2)
      expect(LLM::ProfileMatcher).to have_received(:call).exactly(2).times
    end

    it "aborts if system is paused" do
      SystemSetting.create!(key: "pipelines_paused", value: "true")
      described_class.perform_now
      expect(LLM::ProfileMatcher).not_to have_received(:call)
    end
  end
end
