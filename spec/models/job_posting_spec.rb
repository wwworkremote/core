# frozen_string_literal: true

# == Schema Information
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  body               :string
#  company_name       :string
#  country_code       :string
#  crawl_status       :string
#  data               :jsonb            not null
#  embedding          :vector(3584)
#  enriched_at        :datetime
#  latitude           :float
#  location           :string
#  longitude          :float
#  published_at       :datetime
#  seen_count         :integer          default(1), not null
#  signature          :string           not null
#  status             :string
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint
#
# Indexes
#
#  index_job_postings_on_body                           (body) USING gin
#  index_job_postings_on_company_and_published_at       (company,published_at DESC)
#  index_job_postings_on_company_id                     (company_id)
#  index_job_postings_on_company_name                   (company_name)
#  index_job_postings_on_company_name_and_published_at  (company_name,published_at DESC)
#  index_job_postings_on_country_code                   (country_code)
#  index_job_postings_on_data                           (data) USING gin
#  index_job_postings_on_external_id                    (external_id)
#  index_job_postings_on_location                       (location)
#  index_job_postings_on_published_at                   (published_at)
#  index_job_postings_on_signature                      (signature) UNIQUE
#  index_job_postings_on_source_id_and_published_at     (source_id,published_at DESC)
#  index_job_postings_on_title                          (title) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (source_id => sources.id)
#
require "rails_helper"

RSpec.describe JobPosting do
  describe "validations" do
    subject { described_class.new(signature: "test-sig") }

    it { is_expected.to validate_presence_of(:signature) }
    it { is_expected.to validate_uniqueness_of(:signature) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:source).optional }
    it { is_expected.to have_many(:user_job_postings).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_job_postings) }
  end

  describe "AASM transitions" do
    let(:job) { create(:job_posting, status: "none") }

    it "prevents direct status updates" do
      job.status = "applied"
      expect(job.save).to be false
      expect(job.errors[:status]).to include("cannot be updated directly. Use state machine events.")
    end

    it "permits status updates via events" do
      job.favorite!
      expect(job.status).to eq("favorited")
    end
  end
end
