# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Deep AI Career Alignment (V2)" do
  let(:user) { User.create!(email: "tester@example.com", name: "Tester", password: "password") }
  let(:job1) {
    JobPosting.create!(title: "Ruby Engineer", company: "RemoteCo", body: "We love Ruby and Rails.", signature: "job1")
  }
  let(:job2) {
    JobPosting.create!(title: "Rails Architect", company: "BigCorp", body: "Legacy systems, 10% Rails.",
                       signature: "job2")
  }

  describe LLM::DocumentProcessor do
    it "extracts text from attachments" do
      profile = CareerProfile.create!(user: user, experience_level: "Senior")
      file = StringIO.new("This is my resume content")
      profile.resumes.attach(io: file, filename: "resume.txt", content_type: "text/plain")

      text = described_class.extract_text(profile.resumes.first)
      expect(text).to eq("This is my resume content")
    end
  end

  describe LLM::ProfileMatcher do
    it "includes interview prep in the analysis" do
      # Create profile with work experience to satisfy guard clause
      profile = CareerProfile.create!(user: user, experience_level: "Senior", resume_text: "I am a ruby dev")
      profile.work_experiences.create!(company_name: "Test", title: "Dev", start_date: 1.year.ago)

      user.reload

      allow(LLM::Orchestrator).to receive(:call).and_return({
                                                              success: true,
                                                              output: "MATCH_CONFIDENCE: 90%\nINTERVIEW_PREP:\n1. Question: How do you handle forking?\nAnswer: STAR format..."
                                                            })

      result = described_class.call(user, job1)

      expect(result[:success]).to be true
      expect(result[:output]).to include("INTERVIEW_PREP")
    end
  end

  describe LLM::CareerComparator do
    it "ranks multiple jobs" do
      CareerProfile.create!(user: user, experience_level: "Senior", skills: "Ruby", goals: "Remote")
      user.reload

      allow(LLM::Orchestrator).to receive(:call).and_return({
                                                              success: true,
                                                              output: "RANKING:\n1. Job1\n2. Job2"
                                                            })

      result = described_class.call(user, [job1, job2])
      expect(result[:success]).to be true
      expect(result[:output]).to include("RANKING")
    end
  end
end
