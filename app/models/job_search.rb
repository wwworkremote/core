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
    VectorIntelligence.rank(source: resume, target_class: JobPosting, limit: limit)
  end

  def skill_matches(limit: 10)
    VectorIntelligence.rank(source: resume, target_class: Skill, limit: limit)
  end
end
