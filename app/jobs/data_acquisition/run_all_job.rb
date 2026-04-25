# frozen_string_literal: true

class DataAcquisition::RunAllJob < ApplicationJob
  queue_as :light
  mediumweight!
  idempotent!

  def perform
    DataAcquisitionManager.run_all
  end
end
