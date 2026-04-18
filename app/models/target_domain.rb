# frozen_string_literal: true

class TargetDomain < ApplicationRecord
  belongs_to :job_posting
  belongs_to :domain
end

# == Schema Information
#
# Table name: target_domains
# Database name: primary
#
#  id             :bigint           not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  domain_id      :bigint           not null
#  job_posting_id :bigint           not null
#
# Indexes
#
#  index_target_domains_on_domain_id                     (domain_id)
#  index_target_domains_on_domain_id_and_job_posting_id  (domain_id,job_posting_id) UNIQUE
#  index_target_domains_on_job_posting_id                (job_posting_id)
#  index_target_domains_on_job_posting_id_and_domain_id  (job_posting_id,domain_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (domain_id => domains.id)
#  fk_rails_...  (job_posting_id => job_postings.id)
#
