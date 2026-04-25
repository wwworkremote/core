# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_steps
#
#  id             :bigint           not null, primary key
#  link           :string
#  note           :text
#  notes          :text
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_pipeline_steps_on_job_posting_id  (job_posting_id)
#  index_pipeline_steps_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :pipeline_step do
    job_posting { nil }
    status { "MyString" }
    notes { "MyText" }
  end
end
