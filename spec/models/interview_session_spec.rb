# frozen_string_literal: true

# == Schema Information
#
# Table name: interview_sessions
#
#  id             :bigint           not null, primary key
#  feedback       :text
#  interviewers   :string
#  notes          :text
#  outcome        :string           default("pending"), not null
#  position       :integer
#  scheduled_at   :datetime
#  session_type   :string
#  vibe           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_interview_sessions_on_job_posting_id  (job_posting_id)
#  index_interview_sessions_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe InterviewSession do
  describe "associations" do
    it { is_expected.to belong_to(:job_posting) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:interview_questions).dependent(:destroy) }
    it { is_expected.to have_many_attached(:artifacts) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:session_type) }
    it { is_expected.to validate_inclusion_of(:outcome).in_array(described_class::OUTCOMES) }

    it "requires scheduled_at once a round has an outcome" do
      session = build(:interview_session, scheduled_at: nil, outcome: "advanced")
      expect(session).not_to be_valid
      expect(session.errors[:scheduled_at]).to be_present
    end

    it "allows a pending placeholder round with no scheduled_at" do
      expect(build(:interview_session, :placeholder)).to be_valid
    end
  end

  describe "constants" do
    it "defines SESSION_TYPES" do
      expect(described_class::SESSION_TYPES).to include("Technical")
    end
  end

  describe "advancing the tracked application on create" do
    let(:user) { create(:user) }
    let(:job_posting) { create(:job_posting) }

    it "moves the matching UserJobPosting from applied to interview" do
      ujp = create(:user_job_posting, user:, job_posting:, status: "applied")

      create(:interview_session, user:, job_posting:)

      expect(ujp.reload.status).to eq("interview")
    end

    it "logs the transition to the pipeline timeline" do
      create(:user_job_posting, user:, job_posting:, status: "favorited")

      expect { create(:interview_session, user:, job_posting:) }
        .to change { PipelineStep.where(user:, job_posting:, status: "interview").count }.by(1)
    end

    it "is a no-op when the application can't advance (already archived)" do
      ujp = create(:user_job_posting, user:, job_posting:, status: "archived")

      create(:interview_session, user:, job_posting:)

      expect(ujp.reload.status).to eq("archived")
    end

    it "is a no-op when the posting was never tracked" do
      expect { create(:interview_session, user:, job_posting:) }.not_to raise_error
    end

    it "does not move the pipeline for an unscheduled placeholder round" do
      ujp = create(:user_job_posting, user:, job_posting:, status: "applied")

      create(:interview_session, :placeholder, user:, job_posting:)

      expect(ujp.reload.status).to eq("applied")
    end

    it "advances when a date is later booked on a placeholder round" do
      ujp = create(:user_job_posting, user:, job_posting:, status: "applied")
      round = create(:interview_session, :placeholder, user:, job_posting:)

      round.update!(scheduled_at: 1.day.from_now)

      expect(ujp.reload.status).to eq("interview")
    end
  end
end
