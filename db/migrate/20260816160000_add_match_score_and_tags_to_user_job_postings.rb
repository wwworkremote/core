# frozen_string_literal: true

# ProfileMatcher already computes a MATCH_CONFIDENCE score and evaluates
# explicit criteria (remote purity, tech-stack density, seniority alignment,
# red flags) via LLM -- it just threw the score away except for a boolean
# priority_flag, and never persisted structured tags at all. Real columns,
# not user_job_postings.strategy jsonb (already used by a separate concern,
# JobBoards::StrategyAgent) -- this is meant to be sorted/filtered on, the
# same reasoning as TASK-12's job_boards_documents_count counter cache.
class AddMatchScoreAndTagsToUserJobPostings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # rubocop:disable Rails/BulkChangeTable -- strong_migrations can't inspect
  # inside a change_table bulk block to verify safety; plain statements keep
  # its per-statement checks intact.
  def change
    add_column :user_job_postings, :match_score, :integer
    add_column :user_job_postings, :match_tags, :text, array: true, default: [], null: false
    add_index :user_job_postings, :match_score, algorithm: :concurrently
  end
  # rubocop:enable Rails/BulkChangeTable
end
