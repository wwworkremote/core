# frozen_string_literal: true

# TASK-38: the local embed server now serves nomic-embed-text-v2-moe
# (768 dims) instead of the Qwen2.5-7B hidden-state pooling that produced
# the original 3584-dim vectors. Existing embeddings are incompatible with
# the new model's output space, not just a different size -- they must be
# cleared and regenerated (see bin/reembed), not migrated in place.
# rubocop:disable-next Metrics/MethodLength
class MigrateEmbeddingsTo768Dimensions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  TABLES = %w[job_postings career_profiles resumes skills system_insights].freeze

  def up
    TABLES.each { |table| migrate_table(table, 768) }
  end

  def down
    TABLES.each { |table| migrate_table(table, 3584) }
  end

  private

  def migrate_table(table, dimensions)
    safety_assured do
      execute "DROP INDEX CONCURRENTLY IF EXISTS index_#{table}_on_embedding_hnsw;"
      execute "UPDATE #{table} SET embedding = NULL;"
      change_column table.to_sym, :embedding, :vector, limit: dimensions
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_#{table}_on_embedding_hnsw
        ON #{table} USING hnsw ((embedding::halfvec(#{dimensions})) halfvec_cosine_ops);
      SQL
    end
  end
end
