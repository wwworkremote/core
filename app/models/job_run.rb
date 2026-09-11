# frozen_string_literal: true

# Durable log of every ActiveJob execution's lifecycle (start/finish/error),
# independent of SolidQueue's own job rows -- those get pruned hourly
# (see config/recurring.yml's clear_solid_queue_finished_jobs) and never
# recorded a start time in the first place. Populated by the
# ActiveSupport::Notifications subscriber in
# config/initializers/job_run_tracking.rb, not written to directly elsewhere.
# == Schema Information
#
# Table name: job_runs
#
#  id            :bigint           not null, primary key
#  error_message :text
#  finished_at   :datetime
#  job_class     :string           not null
#  queue_name    :string
#  started_at    :datetime         not null
#  status        :string           default("running"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active_job_id :string           not null
#
# Indexes
#
#  index_job_runs_on_active_job_id             (active_job_id)
#  index_job_runs_on_job_class_and_created_at  (job_class,created_at)
#  index_job_runs_on_status_and_created_at     (status,created_at)
#
class JobRun < ApplicationRecord
  STATUSES = %w[running finished failed].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
end
