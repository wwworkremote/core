# frozen_string_literal: true

# == Schema Information
#
# Table name: application_questions
#
#  id             :bigint           not null, primary key
#  answer_source  :string
#  answer_text    :text
#  question_text  :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_application_questions_on_job_posting_id  (job_posting_id)
#  index_application_questions_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe ApplicationQuestion do
  describe "associations" do
    it { is_expected.to belong_to(:job_posting) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:question_text) }
  end

  describe "constants" do
    it "defines SOURCES" do
      expect(described_class::SOURCES).to eq(%w[canned ai submitted])
    end
  end
end
