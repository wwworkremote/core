# frozen_string_literal: true

# == Schema Information
#
# Table name: interview_tasks
#
#  id             :bigint           not null, primary key
#  description    :text
#  due_at         :datetime
#  status         :string
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_interview_tasks_on_job_posting_id  (job_posting_id)
#  index_interview_tasks_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :interview_task do
    user
    job_posting
    title { "Prepare for interview" }
    status { "pending" }
  end
end
