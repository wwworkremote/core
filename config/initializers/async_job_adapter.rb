# frozen_string_literal: true

require 'async/job/processor/inline'

# Ensure the adapter is loaded before we patch it
begin
  require 'active_job/queue_adapters/async_job_adapter'
rescue LoadError
  # Fallback in case the path is different
end

# Mission Control Jobs expects adapters to implement a specific interface.
# We provide minimal implementations to prevent crashes.
module MissionControlAsyncJobAdapterExtension
  def activating(&)
    yield
  end

  def queues
    []
  end

  def queue_names
    []
  end

  def queue_size(*)
    0
  end

  def clear_queue(*)
  end

  def pause_queue(*)
  end

  def resume_queue(*)
  end

  def queue_paused?(*)
    false
  end

  def jobs_count(*)
    0
  end

  def fetch_jobs(*)
    []
  end

  def retry_all_jobs(*)
  end

  def retry_job(*)
  end

  def discard_all_jobs(*)
  end

  def discard_job(*)
  end

  def dispatch_job(*)
  end

  def find_job(*)
    nil
  end

  def finished_jobs
    []
  end

  def failed_jobs
    []
  end

  def scheduled_jobs
    []
  end

  def paused_queues
    []
  end

  def supported_job_statuses
    [:pending, :failed]
  end

  def supports_filtering?
    false
  end

  def recurring_tasks
    []
  end
end

# Apply the extension to the adapter class
if defined?(ActiveJob::QueueAdapters::AsyncJobAdapter)
  # Include the base module first so our extension can override its default methods
  ActiveJob::QueueAdapters::AsyncJobAdapter.include(MissionControl::Jobs::Adapter) if defined?(MissionControl::Jobs::Adapter)
  ActiveJob::QueueAdapters::AsyncJobAdapter.prepend(MissionControlAsyncJobAdapterExtension)
end

Rails.application.configure do
  config.async_job.define_queue 'default' do
    dequeue Async::Job::Processor::Inline
  end
end
