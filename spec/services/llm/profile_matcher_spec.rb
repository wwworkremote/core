# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::ProfileMatcher do
  let(:user) { create(:user) }
  let!(:career_profile) { create(:career_profile, user: user, resume_text: "Experienced Ruby developer.") }
  let!(:job_posting) { create(:job_posting, title: "Senior Ruby Engineer", body: "We need a Ruby expert.") }
  let!(:model) { create(:model, model_id: "llama3.2:latest", provider: "ollama") }

  before do
    allow(LLM::Registry).to receive(:default_model).and_return(model)
    create(:work_experience, career_profile: career_profile, title: "Lead Developer", company_name: "Tech Corp")
    # Stub PDF processing to avoid external library dependency in this spec
    allow(LLM::DocumentProcessor).to receive(:extract_pdf_text_for_all).and_return([])
  end

  describe ".call" do
    it "performs alignment scan and extracts score using real HTTP simulation" do
      mock_output = <<~MARKDOWN
        # ANALYSIS
        1. **MATCH_CONFIDENCE**: 85%
        2. **STRENGTHS**: Great Ruby skills and Lead experience.
      MARKDOWN

      # Realistic SSE format for RubyLLM
      sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{mock_output.to_json}}}]}\n\ndata: [DONE]\n"

      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

      result = described_class.call(user, job_posting)

      expect(result[:success]).to be true
      expect(result[:score]).to eq(85)

      user_job = user.user_job_postings.find_by(job_posting: job_posting)
      expect(user_job.match_analysis).to eq(mock_output)
      expect(user_job.priority_flag).to be true
    end

    it "fails gracefully if profile is incomplete" do
      # CareerProfile creation above has resume_text. Let's make a new user without one.
      incomplete_user = create(:user, email: "incomplete@example.com")
      create(:career_profile, user: incomplete_user, resume_text: nil)

      result = described_class.call(incomplete_user, job_posting)
      expect(result[:success]).to be false
      expect(result[:error]).to include("Profile incomplete")
    end

    it "handles LLM failures accurately" do
      stub_request(:post, "http://localhost:11500/v1/chat/completions")
        .to_return(status: 500, body: "Error")

      result = described_class.call(user, job_posting)
      expect(result[:success]).to be false
      expect(result[:error]).to include("Model execution failed")
    end
  end
end
