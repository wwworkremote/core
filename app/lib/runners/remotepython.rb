# frozen_string_literal: true

module Runner
  module RemotePython
    module_function

    def run(term:)
      Runners::RemotePython::Runner.new(term: term).call
    end
  end
end
