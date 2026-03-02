# frozen_string_literal: true

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
