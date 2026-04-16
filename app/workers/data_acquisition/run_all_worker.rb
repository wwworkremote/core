# frozen_string_literal: true

module DataAcquisition
  class RunAllWorker
    include Sidekiq::Worker

    def perform
      DataAcquisitionManager.run_all
    end
  end
end
