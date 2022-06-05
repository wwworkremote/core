# frozen_string_literal: true

module Runners
  module RemotePython
    module_function

    def run(term:)
      Runners::RemotePython::Runner.new(term:).call
    end

    def async(term:)
      Runners::RemotePython::Async.perform_async(term)
    end
  end
end
