# frozen_string_literal: true

module Runners
  module WeWorkRemotely
    module_function

    def run(term:)
      Runners::WeWorkRemotely::Runner.new(term: term).call
    end

    def async(term:)
      Runners::WeWorkRemotely::Async.perform_async(term: term)
    end
  end
end
