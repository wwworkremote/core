# frozen_string_literal: true

class UpdateEmbeddingDimensions < ActiveRecord::Migration[8.0]
  def up
    safety_assured { change_column :job_postings, :embedding, :vector, limit: 3584 }
  end

  def down
    safety_assured { change_column :job_postings, :embedding, :vector, limit: 1536 }
  end
end
