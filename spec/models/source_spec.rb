# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Source, type: :model do
  describe 'associations' do
    it 'belongs to origin' do
      association = described_class.reflect_on_association(:origin)
      expect(association.macro).to eq :belongs_to
    end

    it 'has many job_postings' do
      association = described_class.reflect_on_association(:job_postings)
      expect(association.macro).to eq :has_many
    end
  end
end
