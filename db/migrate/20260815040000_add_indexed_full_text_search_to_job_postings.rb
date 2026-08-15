# frozen_string_literal: true

# pg_search's :search scope was computing to_tsvector live against
# title+body on every query -- a full sequential scan (~3s over 4.5k rows).
# Store the tsearch document as a generated column and index it.
#
# The trigram half is scoped to title only (see JobPosting's pg_search_scope
# trigram: { only: [:title] }) rather than indexed against title+body: fuzzy
# trigram matching against multi-KB body text is expensive per row
# regardless of indexing (the trigram set for a long document is huge), and
# isn't a good fit for full-body search anyway -- tsearch (stemmed) and the
# vector half of hybrid_search already cover body content. Title is short
# enough that even a sequential scan on it is cheap (~26ms measured).
# rubocop:disable Metrics/MethodLength
class AddIndexedFullTextSearchToJobPostings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<~SQL.squish
        ALTER TABLE job_postings ADD COLUMN tsv_search tsvector
        GENERATED ALWAYS AS (
          setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(body, '')), 'B')
        ) STORED;
      SQL

      execute <<~SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_job_postings_on_tsv_search
        ON job_postings USING gin (tsv_search);
      SQL
    end
  end

  def down
    safety_assured do
      execute "DROP INDEX CONCURRENTLY IF EXISTS index_job_postings_on_tsv_search;"
      execute "ALTER TABLE job_postings DROP COLUMN IF EXISTS tsv_search;"
    end
  end
end
# rubocop:enable Metrics/MethodLength
