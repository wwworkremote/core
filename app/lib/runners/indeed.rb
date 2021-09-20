# frozen_string_literal: true

module Runners
  module Indeed
    module_function

    def run(term:)
      Runners::Indeed::Runner.new(term: term).call
    end
  end
end
