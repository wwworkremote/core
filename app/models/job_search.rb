# frozen_string_literal: true

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
