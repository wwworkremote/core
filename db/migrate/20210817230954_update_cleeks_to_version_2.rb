# frozen_string_literal: true

class UpdateCleeksToVersion2 < ActiveRecord::Migration[6.1]
  def change
    update_view :cleeks, version: 2, revert_to_version: 1
  end
end
