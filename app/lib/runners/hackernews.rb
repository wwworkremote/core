# frozen_string_literal: true

module Runners
  module HackerNews
    module_function

    def run(term:)
      Runners::HackerNews::Runner.new(term: term).call
    end
  end
end
