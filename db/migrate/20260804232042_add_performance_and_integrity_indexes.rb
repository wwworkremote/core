# frozen_string_literal: true

# rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
class AddPerformanceAndIntegrityIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :domains, :root_domain_id, algorithm: :concurrently, if_not_exists: true
    remove_index :career_profiles, name: "index_career_profiles_on_embedding", algorithm: :concurrently, if_exists: true

    safety_assured do
      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_career_profiles_on_embedding_hnsw#{' '}
        ON career_profiles USING hnsw ((embedding::halfvec(3584)) halfvec_cosine_ops);
      SQL

      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_job_postings_on_embedding_hnsw#{' '}
        ON job_postings USING hnsw ((embedding::halfvec(3584)) halfvec_cosine_ops);
      SQL

      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_resumes_on_embedding_hnsw#{' '}
        ON resumes USING hnsw ((embedding::halfvec(3584)) halfvec_cosine_ops);
      SQL

      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_skills_on_embedding_hnsw#{' '}
        ON skills USING hnsw ((embedding::halfvec(3584)) halfvec_cosine_ops);
      SQL

      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_system_insights_on_embedding_hnsw#{' '}
        ON system_insights USING hnsw ((embedding::halfvec(3584)) halfvec_cosine_ops);
      SQL
    end

    add_foreign_key :user_job_postings, :job_searches, validate: false, if_not_exists: true
  end

  def down
    remove_foreign_key :user_job_postings, :job_searches, if_exists: true
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_system_insights_on_embedding_hnsw;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_skills_on_embedding_hnsw;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_resumes_on_embedding_hnsw;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_job_postings_on_embedding_hnsw;"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_career_profiles_on_embedding_hnsw;"
    remove_index :domains, :root_domain_id, algorithm: :concurrently, if_exists: true
  end
end
