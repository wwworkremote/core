# frozen_string_literal: true

class UpdateEmbeddingDimensions < ActiveRecord::Migration[8.0]
  def change
    safety_assured { change_column :job_postings, :embedding, :vector, limit: 3584 }
  end
end
