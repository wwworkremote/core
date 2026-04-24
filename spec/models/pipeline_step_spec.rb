# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_steps
#
#  id             :bigint           not null, primary key
#  link           :string
#  note           :text
#  notes          :text
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint
#
# Indexes
#
#  index_pipeline_steps_on_job_posting_id  (job_posting_id)
#  index_pipeline_steps_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
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
