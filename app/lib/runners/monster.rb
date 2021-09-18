# frozen_string_literal: true

module Runners
  module Monster
    module_function

    def run(term:)
      Runners::Monster::Runner.new(term: term).call
    end
  end
end
