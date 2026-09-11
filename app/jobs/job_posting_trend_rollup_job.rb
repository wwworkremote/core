# frozen_string_literal: true

class JobPostingTrendRollupJob < ApplicationJob
  queue_as :low
  mediumweight!

  def perform
    JobPostingTrendRollup.call
  end
end
