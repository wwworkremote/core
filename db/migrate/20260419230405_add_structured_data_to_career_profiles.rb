# frozen_string_literal: true

class AddStructuredDataToCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    change_table :career_profiles, bulk: true do |t|
      t.jsonb :contact_info
      t.jsonb :location_info
    end
  end
end
