# frozen_string_literal: true

module Runners
  module StackOverflow
    module_function

    def run(term:)
      Runners::StackOverflow::Runner.new(term:).call
    end

    def async(term:)
      Runners::StackOverflow::Async.perform_async(term)
    end
  end
end
