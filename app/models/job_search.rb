# frozen_string_literal: true

# == Schema Information
#
# Table name: job_searches
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  status     :string           default("active"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  resume_id  :bigint
#  user_id    :bigint           not null
#
# Indexes
#
#  index_job_searches_on_resume_id  (resume_id)
#  index_job_searches_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (resume_id => resumes.id)
#  fk_rails_...  (user_id => users.id)
#
class JobSearch < ApplicationRecord
  belongs_to :user
  belongs_to :resume, optional: true

  has_many :user_job_postings, dependent: :nullify

  validates :name, presence: true

  enum :status, {
    active: "active",
    closed: "closed"
  }, default: :active

  def matches(limit: 10)
    JobSearchManager::MatcherService.new(self).call(limit: limit)
  end

  def skill_matches(limit: 10)
    JobSearchManager::MatcherService.new(self).skills_analysis(limit: limit)
  end
end
