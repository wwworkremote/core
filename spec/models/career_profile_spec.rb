# frozen_string_literal: true

# == Schema Information
#
# Table name: career_profiles
#
#  id               :bigint           not null, primary key
#  contact_info     :jsonb
#  embedding        :vector(3584)
#  experience_level :string
#  github_context   :jsonb
#  github_url       :string
#  goals            :text
#  location_info    :jsonb
#  resume_text      :text
#  skills           :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_career_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe CareerProfile do
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
