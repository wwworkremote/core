# frozen_string_literal: true

module Runners
  module HackerNews
    module_function

    def run(term:)
      Runners::HackerNews::Runner.new(term: term).call
    end

    def async(term:)
      Runners::HackerNews::Async.perform_async(term: term)
    end
  end
end
