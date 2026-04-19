# frozen_string_literal: true

require 'async/job/processor/inline'

# Mission Control Jobs expects the adapter to respond to #activating
# and other querying methods like #queues.
module AsyncJobAdapterActivatingPatch
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
end

ActiveSupport.on_load(:active_job) do
  ActiveJob::QueueAdapters::AsyncJobAdapter.include(AsyncJobAdapterActivatingPatch)
end

Rails.application.configure do
  config.async_job.define_queue 'default' do
    dequeue Async::Job::Processor::Inline
  end
end
