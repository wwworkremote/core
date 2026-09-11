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
FactoryBot.define do
  factory :interview_session do
    user
    job_posting
    session_type { "Screening" }
    scheduled_at { 2.days.from_now }

    # An unscheduled placeholder round from a seeded process.
    trait :placeholder do
      scheduled_at { nil }
    end

    trait :advanced do
      outcome { "advanced" }
    end

    trait :rejected do
      outcome { "rejected" }
    end
  end
end
