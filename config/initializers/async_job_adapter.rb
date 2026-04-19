# frozen_string_literal: true

require 'async/job/processor/inline'

# Mission Control Jobs expects the adapter to respond to #activating
# to wrap block execution within the adapter's context.
module AsyncJobAdapterActivatingPatch
  def activating(&)
    yield
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
