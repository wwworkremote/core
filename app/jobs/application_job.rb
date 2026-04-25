# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Enforce transaction-safe job enqueuing per SolidQueue skill best practices
  self.enqueue_after_transaction_commit = true

  before_perform do |job|
    if SystemSetting.paused?
      Rails.logger.info "[PauseSignal] Job #{job.class.name} (#{job.job_id}) cancelled due to global pause."
      throw :abort
    end

    if SystemSetting.job_cancelled?(job.job_id)
      Rails.logger.info "[CancelSignal] Job #{job.class.name} (#{job.job_id}) aborted via user request."
      SystemSetting.clear_job_cancellation!(job.job_id)
      throw :abort
    end
  end

  after_perform do |job|
    SystemSetting.clear_job_cancellation!(job.job_id)
  end

  def check_cancellation!
    return unless SystemSetting.job_cancelled?(job_id)
    Rails.logger.info "[CancelSignal] Job #{self.class.name} (#{job_id}) terminating mid-performance."
    SystemSetting.clear_job_cancellation!(job_id)
    throw :abort
  end

  # Solid Queue Concurrency Helpers

  def self.heavyweight!
    job_class = name
    limits_concurrency to: 2, group: 'heavyweight', key: ->(*_args) { job_class }
  end

  def self.mediumweight!
    job_class = name
    limits_concurrency to: 5, group: 'mediumweight', key: ->(*_args) { job_class }
  end

  def self.lightweight!
    job_class = name
    limits_concurrency to: 20, group: 'lightweight', key: ->(*_args) { job_class }
  end

  # Ensures only one instance of this job with these arguments can be enqueued or running
  def self.idempotent!(key_proc = nil)
    job_class = name
    # Default key is the job class + arguments if no proc provided
    # The key proc receives the JOB ARGUMENTS as separate arguments
    key_proc ||= ->(*args) { "#{job_class}/#{args.join('-')}" }
    limits_concurrency key: key_proc
  end
end
