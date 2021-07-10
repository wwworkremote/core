# frozen_string_literal: true

class AddStatusToNotificationsRequestFaradays < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications_request_faradays, :status, :integer, default: 0
  end
end
