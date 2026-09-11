# frozen_string_literal: true

class AddEmbeddingToCareerProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :career_profiles, :embedding, :vector, limit: 1536
  end
end
