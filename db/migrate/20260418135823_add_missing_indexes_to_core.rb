# frozen_string_literal: true

class AddMissingIndexesToCore < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # JobPostings: Performance for common filters and sorting
    add_index :job_postings, :company, algorithm: :concurrently
    add_index :job_postings, :location, algorithm: :concurrently
    add_index :job_postings, :published_at, algorithm: :concurrently
    add_index :job_postings, :external_id, algorithm: :concurrently

    # JSONB optimization for AI categorization and metadata
    add_index :job_postings, :data, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
    add_index :sources, :payload, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
    add_index :sources, :event, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
  end
end
