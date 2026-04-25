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
#  index_companies_on_slug  (slug)
#
require 'rails_helper'

RSpec.describe Company do
  describe 'associations' do
    it { is_expected.to have_many(:job_postings) }
    it { is_expected.to have_many(:company_pipeline_steps).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe 'states' do
    let(:company) { described_class.new(name: 'Test Corp', slug: 'test-corp') }

    it 'starts in none state' do
      expect(company.status).to eq('none')
    end

    it 'can transition to favorited' do
      company.favorite
      expect(company.status).to eq('favorited')
    end
  end

  describe 'intelligence' do
    let(:company) { create(:company, toxic_culture_flag: true) }

    it 'identifies toxic culture' do
      expect(company.toxic_culture_flag).to be true
    end
  end
end
