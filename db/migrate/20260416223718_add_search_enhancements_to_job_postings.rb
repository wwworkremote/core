# frozen_string_literal: true

class AddSearchEnhancementsToJobPostings < ActiveRecord::Migration[8.0]
  def change
    add_column :job_postings, :embedding, :vector, limit: 1536 # Default for OpenAI or larger local models

    # Add GIN index for fast full-text/trigram search
    add_index :job_postings, :title, using: :gin, opclass: :gin_trgm_ops
    add_index :job_postings, :body, using: :gin, opclass: :gin_trgm_ops
  end
end
