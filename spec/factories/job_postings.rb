# frozen_string_literal: true

# == Schema Information
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  body               :string
#  company            :string
#  crawl_status       :string
#  data               :jsonb            not null
#  embedding          :vector(3584)
#  enriched_at        :datetime
#  latitude           :float
#  location           :string
#  longitude          :float
#  published_at       :datetime
#  signature          :string           not null
#  status             :string
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint
#
# Indexes
#
#  index_job_postings_on_body                        (body) USING gin
#  index_job_postings_on_company                     (company)
#  index_job_postings_on_company_and_published_at    (company,published_at DESC)
#  index_job_postings_on_data                        (data) USING gin
#  index_job_postings_on_external_id                 (external_id)
#  index_job_postings_on_location                    (location)
#  index_job_postings_on_published_at                (published_at)
#  index_job_postings_on_source_id                   (source_id)
#  index_job_postings_on_source_id_and_published_at  (source_id,published_at DESC)
#  index_job_postings_on_title                       (title) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
FactoryBot.define do
  factory :job_posting do
    title { 'Software Engineer' }
    company { 'Tech Corp' }
    target_url { 'https://example.com/jobs/1' }
    body { 'Job description goes here.' }
    signature { SecureRandom.hex(16) }
  end
end
