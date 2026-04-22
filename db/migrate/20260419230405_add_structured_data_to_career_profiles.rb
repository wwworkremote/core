# frozen_string_literal: true

class AddStructuredDataToCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :career_profiles, :contact_info, :jsonb
    add_column :career_profiles, :location_info, :jsonb
  end
end
