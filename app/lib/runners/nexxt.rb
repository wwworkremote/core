# frozen_string_literal: true

module Runner
  module Nexxt
    module_function

    def run(term:)
      Runners::Nexxt::Runner.new(term: term).call
    end
  end
end
