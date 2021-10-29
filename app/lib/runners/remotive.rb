# frozen_string_literal: true

module Runners
  module Remotive
    module_function

    def run(term:)
      Runners::Remotive::Runner.new(term: term).call
    end

    def async(term:)
      Runners::Remotive::Async.perform_async(term)
    end
  end
end
