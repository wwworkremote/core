# frozen_string_literal: true

class CleanupDatabaseSchema < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # 1. Validate Solid Queue Foreign Keys (previously added with validate: false)
    validate_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_ready_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_failed_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs

    # 2. Remove Redundant Indexes
    # Covered by index_models_on_provider_and_model_id
    remove_index :models, :provider, algorithm: :concurrently

    # Covered by index_target_domains_on_domain_id_and_job_posting_id
    remove_index :target_domains, :domain_id, algorithm: :concurrently

    # Covered by index_target_domains_on_job_posting_id_and_domain_id
    remove_index :target_domains, :job_posting_id, algorithm: :concurrently
  end
end
