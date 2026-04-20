class ChangeCareerProfileEmbeddingLimit < ActiveRecord::Migration[8.0]
  def up
    safety_assured { change_column :career_profiles, :embedding, :vector, limit: 3584 }
  end

  def down
    safety_assured { change_column :career_profiles, :embedding, :vector, limit: 1536 }
  end
end
