# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string           default(""), not null
#  name            :string           not null
#  password_digest :string
#  slug            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#  index_users_on_slug   (slug) UNIQUE
#
require 'rails_helper'

RSpec.describe User do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }

    it 'validates uniqueness of email case-insensitively' do
      described_class.create!(email: 'existing@example.com', name: 'Existing', slug: 'existing', password: 'password')
      new_user = described_class.new(email: 'EXISTING@example.com', name: 'New', slug: 'new', password: 'password')
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    it 'is valid with email and password (auto-populates name/slug)' do
      user = described_class.new(email: 'test2@example.com', password: 'password')
      expect(user).to be_valid
      user.validate
      expect(user.name).to be_present
      expect(user.slug).to be_present
    end
  end

  describe 'associations' do
    it { is_expected.to have_one(:career_profile).dependent(:destroy) }
    it { is_expected.to have_many(:user_job_postings).dependent(:destroy) }
    it { is_expected.to have_many(:job_postings).through(:user_job_postings) }
  end
end
