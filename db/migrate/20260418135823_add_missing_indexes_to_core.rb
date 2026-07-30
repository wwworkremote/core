# frozen_string_literal: true

class AddMissingIndexesToCore < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_job_posting_filter_indexes
    add_jsonb_search_indexes
  end

  private

  def add_job_posting_filter_indexes
    add_index :job_postings, :company, algorithm: :concurrently
    add_index :job_postings, :location, algorithm: :concurrently
    add_index :job_postings, :published_at, algorithm: :concurrently
    add_index :job_postings, :external_id, algorithm: :concurrently
  end

  def add_jsonb_search_indexes
    add_index :job_postings, :data, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
    add_index :sources, :payload, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
    add_index :sources, :event, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
  end
end
