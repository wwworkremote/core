# frozen_string_literal: true

module Runners
  module StackOverflow
    module_function

    def run(term:)
      Runners::StackOverflow::Runner.new(term: term).call
    end
  end
end
