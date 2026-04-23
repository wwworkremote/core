# frozen_string_literal: true

class InterviewTask < ApplicationRecord
  belongs_to :job_posting
  belongs_to :user

  has_many_attached :artifacts

  validates :title, presence: true
  validates :status, presence: true

  STATUSES = %w[pending in_progress completed blocked].freeze
end
