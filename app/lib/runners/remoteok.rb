# frozen_string_literal: true

module Runners
  module RemoteOK
    module_function

    def run(term:)
      Runners::RemoteOK::Runner.new(term:).call
    end

    def async(term:)
      Runners::RemoteOK::Async.perform_async(term)
    end
  end
end
