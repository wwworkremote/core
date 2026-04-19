# == Schema Information
#
# Table name: user_job_postings
#
#  id             :bigint           not null, primary key
#  match_analysis :text
#  notes          :text
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
class UserJobPosting < ApplicationRecord
  include AASM

  belongs_to :user
  belongs_to :job_posting

  aasm column: :status do
    state :none, initial: true
    state :favorited, :applied, :interview, :offered, :archived

    event :favorite do
      transitions from: [:none, :archived], to: :favorited
    end

    event :apply do
      transitions from: [:favorited, :interview], to: :applied
    end

    event :interview do
      transitions from: [:favorited, :applied], to: :interview
    end

    event :offer do
      transitions from: [:favorited, :applied, :interview], to: :offered
    end

    event :archive do
      transitions from: [:favorited, :applied, :interview, :offered], to: :archived
    end
  end
end
