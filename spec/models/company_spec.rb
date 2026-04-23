# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Company, type: :model do
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
    let(:company) { Company.new(name: 'Test Corp', slug: 'test-corp') }

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
