# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id             :bigint           not null, primary key
#  applied_at     :datetime
#  cover_letter   :text
#  match_analysis :text
#  match_score    :integer
#  match_tags     :text             default([]), not null, is an Array
#  notes          :text
#  outcome        :string
#  outcome_at     :datetime
#  outcome_source :string
#  priority_flag  :boolean
#  status         :string
#  strategy       :jsonb            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  job_search_id  :bigint
#  user_id        :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_applied_at      (applied_at)
#  index_user_job_postings_on_job_posting_id  (job_posting_id)
#  index_user_job_postings_on_job_search_id   (job_search_id)
#  index_user_job_postings_on_match_score     (match_score)
#  index_user_job_postings_on_outcome         (outcome)
#  index_user_job_postings_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (job_search_id => job_searches.id)
#  fk_rails_...  (user_id => users.id)
#
FactoryBot.define do
  factory :user_job_posting do
    user
    job_posting
    status { "favorited" }
    notes { "MyText" }
  end
end
