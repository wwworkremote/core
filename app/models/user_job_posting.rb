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
#  job_search_id  :bigint
#  user_id        :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_job_posting_id  (job_posting_id)
#  index_user_job_postings_on_job_search_id   (job_search_id)
#  index_user_job_postings_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
class UserJobPosting < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :job_posting
  belongs_to :job_search, optional: true

  aasm column: :status, whiny_persistence: true do
    state :none, initial: true
    state :favorited, :applied, :interview, :offered, :archived

    event :favorite do
      transitions from: %i[none archived], to: :favorited
    end

    event :apply do
      transitions from: %i[favorited interview], to: :applied
    end

    event :interview do
      transitions from: %i[favorited applied], to: :interview
    end

    event :offer do
      transitions from: %i[favorited applied interview], to: :offered
    end

    event :archive do
      transitions from: %i[favorited applied interview offered], to: :archived
    end
  end
end
