# frozen_string_literal: true

module Runners
  module WeWorkRemotely
    module_function

    def run(term:)
      Runners::WeWorkRemotely::Runner.new(term: term).call
    end
  end
end
