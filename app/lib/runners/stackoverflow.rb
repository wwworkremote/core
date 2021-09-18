# frozen_string_literal: true

module Runners
  module StackOverflow
    module_function

    def run(term:, logger:)
      Runner.new(
        term: term,
        logger: logger
      ).call
    end
  end
end
