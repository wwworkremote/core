# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::AnswerGenerator do
  let(:user) { create(:user) }
  let!(:profile) { create(:career_profile, user: user) }
  let(:job) { create(:job_posting) }
  let(:question) {
    create(:application_question, user: user, job_posting: job, question_text: "Why do you want to work here?")
  }

  describe ".call" do
    it "answers instantly via a canned match, without calling the LLM" do
      canned_question = create(:application_question, user: user, job_posting: job,
                                                      question_text: "How many years of experience do you have?")
      create(:work_experience, career_profile: profile, start_date: 5.years.ago.to_date, end_date: nil)
      allow(LLM::Orchestrator).to receive(:call)

      result = described_class.call(canned_question)

      expect(result[:success]).to be true
      expect(result[:source]).to eq("canned")
      expect(canned_question.reload.answer_source).to eq("canned")
      expect(LLM::Orchestrator).not_to have_received(:call)
    end

    it "returns error if no work experiences (AI path, incomplete profile)" do
      result = described_class.call(question)

      expect(result[:success]).to be false
      expect(result[:error]).to include("Profile incomplete")
      expect(question.reload.answer_text).to be_nil
    end

    it "generates and attaches an AI answer when profile is complete" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "Ruby stuff", impact: "Scale",
                               start_date: 1.year.ago, company_name: "Tech Corp")

      captured_args = nil
      allow(LLM::Orchestrator).to receive(:call) do |args|
        captured_args = args
        { success: true, output: "I'm excited about this role because..." }
      end

      result = described_class.call(question)

      expect(result[:success]).to be true
      expect(result[:source]).to eq("ai")
      expect(captured_args[:untrusted_text]).to include("Why do you want to work here?")
      expect(captured_args[:untrusted_text]).to include("Dev at Tech Corp")
      expect(question.reload.answer_text).to eq("I'm excited about this role because...")
      expect(question.answer_source).to eq("ai")
    end

    it "aborts for an expired job posting unless forced, but keeps the question saved" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      job.expire!

      result = described_class.call(question)

      expect(result[:success]).to be false
      expect(result[:error]).to include("expired/stale")
      expect(question.reload).to be_persisted
      expect(question.answer_text).to be_nil
    end

    it "handles LLM failures without losing the saved question" do
      create(:work_experience, career_profile: profile, title: "Dev", summary: "A", impact: "B")
      allow(LLM::Orchestrator).to receive(:call).and_return({ success: false, error: "Timed out" })

      result = described_class.call(question)

      expect(result[:success]).to be false
      expect(result[:error]).to eq("Timed out")
      expect(question.reload).to be_persisted
      expect(question.answer_text).to be_nil
    end
  end
end
