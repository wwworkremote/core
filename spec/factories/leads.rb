# frozen_string_literal: true

# == Schema Information
#
# Table name: leads
#
#  id             :bigint           not null, primary key
#  company_name   :string
#  discovery      :jsonb            not null
#  found_at       :datetime         not null
#  location       :string
#  provider       :string           not null
#  raw_html       :text
#  signature      :string           not null
#  status         :string           default("captured"), not null
#  title          :string
#  url            :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint
#  job_posting_id :bigint
#  source_id      :bigint
#
# Indexes
#
#  index_leads_on_company_id      (company_id)
#  index_leads_on_discovery       (discovery) USING gin
#  index_leads_on_job_posting_id  (job_posting_id)
#  index_leads_on_signature       (signature) UNIQUE
#  index_leads_on_source_id       (source_id)
#  index_leads_on_status          (status)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (source_id => sources.id)
#
FactoryBot.define do
  factory :lead do
    sequence(:url) { |n| "https://example.com/jobs/#{n}" }
    provider { "linkedin" }
    sequence(:signature) { |n| "lead-#{n}" }
    found_at { Time.current }
  end
end
