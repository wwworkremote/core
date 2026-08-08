# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id             :bigint           not null, primary key
#  match_analysis :text
#  notes          :text
#  priority_flag  :boolean
#  status         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  job_posting_id :bigint           not null
#  job_search_id  :bigint
#  user_id        :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_job_posting_id  (job_posting_id)
#  index_user_job_postings_on_job_search_id   (job_search_id)
#  index_user_job_postings_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (job_search_id => job_searches.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe UserJobPosting do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:job_posting) }
  end

  describe "states" do
    let(:user_job_posting) { described_class.new }

    it "starts in none state" do
      expect(user_job_posting.status).to eq("none")
    end

    it "can transition to favorited" do
      user_job_posting.status = "none"
      expect(user_job_posting.favorite).to be true
      expect(user_job_posting.status).to eq("favorited")
    end
  end
end
