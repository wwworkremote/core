# frozen_string_literal: true

module Runners
  module AuthenticJobs
    module_function

    def run(term:)
      Runners::AuthenticJobs::Runner.new(term:).call
    end

    def async(term:)
      Runners::AuthenticJobs::Async.perform_async(term)
    end
  end
end
