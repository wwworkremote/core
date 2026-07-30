# frozen_string_literal: true

class AddGitHubToCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    change_table :career_profiles, bulk: true do |t|
      t.string :github_url
      t.jsonb :github_context
    end
  end
end
