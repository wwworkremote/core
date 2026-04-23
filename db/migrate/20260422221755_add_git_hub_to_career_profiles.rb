# frozen_string_literal: true

class AddGitHubToCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :career_profiles, :github_url, :string
    add_column :career_profiles, :github_context, :jsonb
  end
end
