# frozen_string_literal: true

module Runners
  module Nexxt
    module_function

    def run(term:)
      Runners::Nexxt::Runner.new(term:).call
    end

    def async(term:)
      Runners::Nexxt::Async.perform_async(term)
    end
  end
end
