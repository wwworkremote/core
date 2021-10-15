# frozen_string_literal: true

module Runners
  module Monster
    module_function

    def run(term:)
      Runners::Monster::Runner.new(term: term).call
    end

    def async(term:)
      Runners::Monster::Async.perform_async(term)
    end
  end
end
