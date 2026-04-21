# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Solid Queue Concurrency Helpers
  
  def self.heavyweight!
    limits_concurrency to: 2, group: "heavyweight", key: -> { self.class.name }
  end

  def self.mediumweight!
    limits_concurrency to: 5, group: "mediumweight", key: -> { self.class.name }
  end

  def self.lightweight!
    limits_concurrency to: 20, group: "lightweight", key: -> { self.class.name }
  end

  # Ensures only one instance of this job with these arguments can be enqueued or running
  def self.idempotent!(key_proc = nil)
    # Default key is the job class + arguments if no proc provided
    key_proc ||= ->(job) { "#{job.class.name}/#{job.arguments.join('-')}" }
    limits_concurrency key: key_proc
  end
end
