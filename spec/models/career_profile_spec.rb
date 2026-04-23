# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CareerProfile, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:work_experiences).dependent(:destroy) }
    it { is_expected.to have_many(:job_experiences).dependent(:destroy) }
    it { is_expected.to have_many_attached(:resumes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
  end

  describe 'GitHub integration' do
    let(:profile) { create(:career_profile, github_url: 'https://github.com/testuser') }

    it 'permits valid github URLs' do
      profile.github_url = 'https://github.com/another'
      expect(profile).to be_valid
    end
  end
end
