# frozen_string_literal: true

class CleanupDatabaseSchema < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    validate_solid_queue_foreign_keys
    remove_redundant_indexes
  end

  private

  # Previously added with validate: false -- one cohesive list, splitting
  # it further would obscure it, not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def validate_solid_queue_foreign_keys
    validate_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_ready_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_failed_executions, :solid_queue_jobs
    validate_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs
  end

  def remove_redundant_indexes
    # Covered by index_models_on_provider_and_model_id
    remove_index :models, :provider, algorithm: :concurrently

    # Covered by index_target_domains_on_domain_id_and_job_posting_id
    remove_index :target_domains, :domain_id, algorithm: :concurrently

    # Covered by index_target_domains_on_job_posting_id_and_domain_id
    remove_index :target_domains, :job_posting_id, algorithm: :concurrently
  end
end
