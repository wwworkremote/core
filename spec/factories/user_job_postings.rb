# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id             :bigint           not null, primary key
#  match_analysis :text
#  notes          :text
#  priority_flag  :boolean
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_job_posting_id  (job_posting_id)
#  index_user_job_postings_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :user_job_posting do
    user { nil }
    job_posting { nil }
    status { "MyString" }
    notes { "MyText" }
  end
end
