# frozen_string_literal: true

module Runners
  module WeWorkRemotely
    module_function

    def run(term:)
      Runners::WeWorkRemotely::Runner.new(term:).call
    end

    def async(term:)
      Runners::WeWorkRemotely::Async.perform_async(term)
    end
  end
end
