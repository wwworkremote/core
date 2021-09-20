# frozen_string_literal: true

module Runner
  module RemoteOK
    module_function

    def run(term:)
      Runners::RemoteOK::Runner.new(term: term).call
    end
  end
end
