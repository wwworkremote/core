# frozen_string_literal: true

class AddCrossIndexesTargetDomains < ActiveRecord::Migration[6.1]
  def change
    add_index :target_domains, %i[domain_id job_posting_id], unique: true
    add_index :target_domains, %i[job_posting_id domain_id], unique: true
  end
end
