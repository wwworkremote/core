# frozen_string_literal: true

class AddMessagesBelongsToNotificationsRequestFaradays < ActiveRecord::Migration[6.1]
  def change
    add_reference(:messages, :notifications_request_faradays, null: true)
  end
end
