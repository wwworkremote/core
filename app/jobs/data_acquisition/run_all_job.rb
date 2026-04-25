# frozen_string_literal: true

module DataAcquisition
  class RunAllJob < ApplicationJob
    queue_as :light
    mediumweight!
    idempotent!

    def perform
      DataAcquisitionManager.run_all
    end
  end
end
