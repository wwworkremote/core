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

  def stub_llm_response(content)
    sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{content.to_json}}}]}\n\ndata: [DONE]\n"
    stub_request(:post, "http://localhost:11500/v1/chat/completions")
      .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })
  end

  describe ".call" do
    it "performs alignment scan and extracts score and tags using real HTTP simulation" do
      mock_output = <<~MARKDOWN
        # ANALYSIS
        1. **MATCH_CONFIDENCE**: 85%
        2. **TAGS**: remote-strict, ruby-heavy, senior-fit
        3. **STRENGTHS**: Great Ruby skills and Lead experience.
      MARKDOWN
      stub_llm_response(mock_output)

      result = described_class.call(user, job_posting)

      expect(result[:success]).to be true
      expect(result[:score]).to eq(85)
      expect(result[:tags]).to eq(%w[remote-strict ruby-heavy senior-fit])

      user_job = user.user_job_postings.find_by(job_posting: job_posting)
      expect(user_job.match_analysis).to eq(mock_output)
      expect(user_job.match_score).to eq(85)
      expect(user_job.match_tags).to eq(%w[remote-strict ruby-heavy senior-fit])
      expect(user_job.priority_flag).to be true
    end

    it "defaults to an empty tags array when the LLM output has no TAGS line" do
      stub_llm_response("1. **MATCH_CONFIDENCE**: 60%\n2. **STRENGTHS**: Decent fit.")

      result = described_class.call(user, job_posting)

      expect(result[:tags]).to eq([])
      expect(user.user_job_postings.find_by(job_posting: job_posting).match_tags).to eq([])
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

    it "aborts for an expired job posting unless forced" do
      job_posting.expire!

      result = described_class.call(user, job_posting)

      expect(result[:success]).to be false
      expect(result[:error]).to include("expired/stale")
    end

    it "does not set priority_flag when the score is below 80" do
      stub_llm_response("1. **MATCH_CONFIDENCE**: 40%")

      result = described_class.call(user, job_posting)

      expect(result[:score]).to eq(40)
      user_job = user.user_job_postings.find_by(job_posting: job_posting)
      expect(user_job.priority_flag).not_to be true
    end
  end
end
