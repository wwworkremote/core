# frozen_string_literal: true

# == Schema Information
#
# Table name: interview_sessions
#
#  id             :bigint           not null, primary key
#  feedback       :text
#  notes          :text
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
    it { is_expected.to validate_presence_of(:scheduled_at) }
  end

  describe "constants" do
    it "defines SESSION_TYPES" do
      expect(described_class::SESSION_TYPES).to include("Technical")
    end
  end
end
