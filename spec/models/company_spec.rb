# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id                 :bigint           not null, primary key
#  disposition        :string
#  glassdoor_data     :jsonb
#  ingestion_enabled  :boolean          default(TRUE), not null
#  name               :string
#  sentiment_score    :float
#  slug               :string
#  status             :string
#  toxic_culture_flag :boolean
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_companies_on_name  (name) UNIQUE
#  index_companies_on_slug  (slug) UNIQUE
#
require "rails_helper"

RSpec.describe Company do
  describe "associations" do
    it { is_expected.to have_many(:job_postings) }
    it { is_expected.to have_many(:company_pipeline_steps).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe "states" do
    let(:company) { described_class.new(name: "Test Corp", slug: "test-corp") }

    it "starts in none state" do
      expect(company.status).to eq("none")
    end

    it "can transition to favorited" do
      company.favorite
      expect(company.status).to eq("favorited")
    end
  end

  describe "intelligence" do
    let(:company) { create(:company, toxic_culture_flag: true) }

    it "identifies toxic culture" do
      expect(company.toxic_culture_flag).to be true
    end
  end

  describe "#big_tech?" do
    it "matches known big-tech names case-insensitively" do
      ["Meta", "Apple", "Amazon.com Inc", "Netflix", "Google", "Alphabet", "Microsoft", "Nvidia", "Tesla", "Oracle",
       "Salesforce"].each do |name|
        expect(described_class.new(name: name).big_tech?).to be(true), "expected #{name} to match"
      end
    end

    it "does not match unrelated companies, including ones sharing a substring" do
      expect(described_class.new(name: "Metadata Corp").big_tech?).to be false
      expect(described_class.new(name: "Startup Inc").big_tech?).to be false
    end
  end

  describe ".big_tech" do
    it "returns only companies matching the blocklist pattern" do
      meta = create(:company, name: "Meta Platforms")
      startup = create(:company, name: "Startup Inc")

      expect(described_class.big_tech).to contain_exactly(meta)
      expect(described_class.big_tech).not_to include(startup)
    end
  end

  describe "#disable_ingestion!" do
    it "disables ingestion and purges non-purged postings" do
      company = create(:company, ingestion_enabled: true)
      posting = create(:job_posting, company_id: company.id, status: "none")
      already_purged = create(:job_posting, company_id: company.id, status: "purged", signature: "already-purged")

      company.disable_ingestion!

      expect(company.reload.ingestion_enabled).to be false
      expect(posting.reload.status).to eq("purged")
      expect(already_purged.reload.updated_at).to eq(already_purged.created_at)
    end

    it "does not raise for a company with an expired posting" do
      # AASM's purge event has no transition from :expired -- confirmed by
      # reproducing the real failure this backfill hit against production
      # data (Meta had an expired posting), which raised
      # AASM::InvalidTransition and aborted the whole rake task.
      company = create(:company, ingestion_enabled: true)
      expired = create(:job_posting, company_id: company.id, status: "expired")

      expect { company.disable_ingestion! }.not_to raise_error
      expect(expired.reload.status).to eq("expired")
    end
  end
end
