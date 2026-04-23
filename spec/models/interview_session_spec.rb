# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InterviewSession, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:job_posting) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:interview_questions).dependent(:destroy) }
    it { is_expected.to have_many_attached(:artifacts) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:session_type) }
    it { is_expected.to validate_presence_of(:scheduled_at) }
  end

  describe 'constants' do
    it 'defines SESSION_TYPES' do
      expect(described_class::SESSION_TYPES).to include('Technical')
    end
  end
end
