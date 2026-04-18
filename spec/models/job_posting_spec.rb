# frozen_string_literal: true

# == Schema Information
#
# Table name: job_postings
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  body               :string
#  company            :string
#  data               :jsonb            not null
#  embedding          :vector(1536)
#  latitude           :float
#  location           :string
#  longitude          :float
#  published_at       :datetime
#  signature          :string           not null
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
#  index_job_postings_on_body       (body) USING gin
#  index_job_postings_on_source_id  (source_id)
#  index_job_postings_on_title      (title) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (source_id => sources.id)
#
require 'rails_helper'

RSpec.describe JobPosting, type: :model do
  describe 'associations' do
    it 'belongs to source' do
      association = described_class.reflect_on_association(:source)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many target_domains' do
      association = described_class.reflect_on_association(:target_domains)
      expect(association.macro).to eq :has_many
    end
  end

  describe 'creation' do
    it 'can be created with a signature' do
      posting = JobPosting.new(signature: 'test-sig', title: 'Developer')
      expect(posting).to be_valid
    end
  end
end
