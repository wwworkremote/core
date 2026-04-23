# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LLM::ProfileMatcher do
  let(:user) { create(:user) }
  let(:career_profile) { create(:career_profile, user: user, resume_text: 'Experienced Ruby developer.') }
  let(:job_posting) { create(:job_posting, title: 'Senior Ruby Engineer', body: 'We need a Ruby expert.') }

  before do
    allow(user).to receive(:career_profile).and_return(career_profile)
    create(:work_experience, career_profile: career_profile, title: 'Lead Developer', company_name: 'Tech Corp')
  end

  describe '.call' do
    it 'performs alignment scan and extracts score' do
      mock_output = <<~MARKDOWN
        # ANALYSIS
        MATCH_CONFIDENCE: 85%
        STRENGTHS: Great Ruby skills.
      MARKDOWN

      expect(LLM::Orchestrator).to receive(:call).and_return({ success: true, output: mock_output })

      result = described_class.call(user, job_posting)

      expect(result[:success]).to be true
      expect(result[:score]).to eq(85)

      user_job = user.user_job_postings.find_by(job_posting: job_posting)
      expect(user_job.match_analysis).to eq(mock_output)
      expect(user_job.priority_flag).to be true
    end

    it 'fails gracefully if profile is incomplete' do
      career_profile.update!(resume_text: nil)
      allow(career_profile).to receive(:work_experiences).and_return([])

      result = described_class.call(user, job_posting)
      expect(result[:success]).to be false
      expect(result[:error]).to include('Profile incomplete')
    end
  end
end
