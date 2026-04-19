# frozen_string_literal: true

require 'async/job/processor/inline'

# Ensure the adapter is loaded before we patch it
begin
  require 'active_job/queue_adapters/async_job_adapter'
rescue LoadError
  # Fallback in case the path is different
end

# Mission Control Jobs expects adapters to implement a specific interface.
# We explicitly include their base module and provide minimal implementations.
module MissionControlAsyncJobAdapterExtension
  def self.included(base)
    base.include MissionControl::Jobs::Adapter if defined?(MissionControl::Jobs::Adapter)
  end

  def activating(&)
    yield
  end

  def queues
    []
  end

  def jobs
    []
  end

  def find_job(job_id, *)
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

  def queue_size(*)
    0
  end

  def clear_queue(*)
  end
end

# Apply the extension to the adapter class
if defined?(ActiveJob::QueueAdapters::AsyncJobAdapter)
  ActiveJob::QueueAdapters::AsyncJobAdapter.include(MissionControlAsyncJobAdapterExtension)
end

Rails.application.configure do
  config.async_job.define_queue 'default' do
    dequeue Async::Job::Processor::Inline
  end
end
