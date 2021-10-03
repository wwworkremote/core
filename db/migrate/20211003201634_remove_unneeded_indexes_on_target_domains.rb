# frozen_string_literal: true

class RemoveUnneededIndexesOnTargetDomains < ActiveRecord::Migration[6.1]
  def change
    remove_index :target_domains, name: 'index_target_domains_on_domain_id', column: :domain_id
    remove_index :target_domains, name: 'index_target_domains_on_job_posting_id', column: :job_posting_id
  end
end
