# frozen_string_literal: true

class SyncDashboardJob < ApplicationJob
  queue_as :default

  def perform
    JobBoards::Syncer.new.call
  end
end
