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
#  index_job_postings_on_embedding_hnsw                 (((embedding)::halfvec(3584)) halfvec_cosine_ops) USING hnsw
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

    it "nils out the embedding when purged" do
      job.update!(embedding: Array.new(3584, 0.1))
      job.purge!
      expect(job.reload.embedding).to be_nil
    end

    it "permits archiving directly from none, for link-monitor-detected dead links" do
      expect(job.may_archive?).to be true
      job.archive!
      expect(job.status).to eq("archived")
    end
  end

  describe "#company=" do
    it "sets company_name when given a string" do
      job = build(:job_posting, company: "Acme Corp")
      expect(job.company_name).to eq("Acme Corp")
    end

    it "sets the real association when given a Company record" do
      company = create(:company)
      job = build(:job_posting)
      job.company = company
      expect(job.company).to eq(company)
    end
  end

  describe "#company" do
    it "returns the company_name string when no Company association is set" do
      job = build(:job_posting, company: "Acme Corp")
      expect(job.company).to eq("Acme Corp")
    end
  end

  describe ".management_tier" do
    it "matches management and senior-architecture titles" do
      manager = create(:job_posting, title: "Engineering Manager, Payments")
      architect = create(:job_posting, title: "Global Head of Specialist Solutions Architecture")
      create(:job_posting, title: "Senior Software Engineer")

      expect(described_class.management_tier).to contain_exactly(manager, architect)
    end
  end

  describe ".hybrid_search" do
    let(:query_embedding) { Array.new(3584) { rand } }

    before do
      # rails_helper stubs VectorIntelligence.embed to an all-zero vector
      # globally; override here to a specific vector so cosine distance
      # against the vector-only fixture below is meaningful (zero vs zero
      # is degenerate).
      allow(VectorIntelligence).to receive(:embed).and_return(query_embedding)
    end

    it "returns none for a blank query" do
      expect(described_class.hybrid_search("")).to be_empty
    end

    it "returns none when neither the keyword nor vector path finds anything" do
      create(:job_posting, title: "Totally Unrelated Posting")

      expect(described_class.hybrid_search("Zorblexicon")).to be_empty
    end

    it "fuses a keyword-only match and a vector-only match, excluding a non-match" do
      keyword_match = create(:job_posting, title: "Senior Zorblexicon Specialist")
      vector_match = create(:job_posting, title: "Generic Analyst Role", embedding: query_embedding)
      control = create(:job_posting)

      results = described_class.hybrid_search("Zorblexicon")

      expect(results).to include(keyword_match, vector_match)
      expect(results).not_to include(control)
    end
  end

  describe "#company_record" do
    it "finds the Company matching the current company name" do
      company = create(:company, name: "Acme Corp")
      job = create(:job_posting, company: "Acme Corp")

      expect(job.company_record).to eq(company)
    end

    it "returns nil and memoizes when no matching Company exists" do
      job = create(:job_posting, company: "Nonexistent Inc")

      expect(job.company_record).to be_nil
      expect(job.instance_variable_get(:@company_record)).to be_nil
    end
  end

  describe "#enforce_commute_zone" do
    it "ignores the posting when Geo::CommuteZone reports it as blocked" do
      job = create(:job_posting, status: "none")
      allow(Geo::CommuteZone).to receive(:call).with(job).and_return(:blocked)

      job.send(:enforce_commute_zone)

      expect(job.status).to eq("ignored")
    end

    it "leaves the posting alone when allowed or undetermined" do
      job = create(:job_posting, status: "none")
      allow(Geo::CommuteZone).to receive(:call).with(job).and_return(:undetermined)

      job.send(:enforce_commute_zone)

      expect(job.status).to eq("none")
    end

    it "does not attempt an invalid AASM transition on an already-favorited posting" do
      job = create(:job_posting, status: "none")
      job.favorite!
      allow(Geo::CommuteZone).to receive(:call).with(job).and_return(:blocked)

      expect { job.send(:enforce_commute_zone) }.not_to raise_error
      expect(job.status).to eq("favorited")
    end
  end
end
