# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PipelineStep, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:job_posting) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many_attached(:artifacts) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
  end
end
