# frozen_string_literal: true

# == Schema Information
#
# Table name: user_job_postings
#
#  id                           :bigint           not null, primary key
#  application_profile_snapshot :jsonb            not null
#  applied_at                   :datetime
#  cover_letter                 :text
#  match_analysis               :text
#  match_score                  :integer
#  match_tags                   :text             default([]), not null, is an Array
#  notes                        :text
#  outcome                      :string
#  outcome_at                   :datetime
#  outcome_source               :string
#  priority_flag                :boolean
#  resume_persona_snapshot      :jsonb            not null
#  status                       :string
#  strategy                     :jsonb            not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  application_trace_id         :string
#  job_posting_id               :bigint           not null
#  job_search_id                :bigint
#  resume_persona_id            :string
#  user_id                      :bigint           not null
#
# Indexes
#
#  index_user_job_postings_on_application_trace_id  (application_trace_id)
#  index_user_job_postings_on_applied_at            (applied_at)
#  index_user_job_postings_on_job_posting_id        (job_posting_id)
#  index_user_job_postings_on_job_search_id         (job_search_id)
#  index_user_job_postings_on_match_score           (match_score)
#  index_user_job_postings_on_outcome               (outcome)
#  index_user_job_postings_on_user_id               (user_id)
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

    it "can apply directly from none without favoriting first" do
      expect(user_job_posting.may_apply?).to be true
    end
  end

  describe "#record_status_event!" do
    let(:user_job_posting) { create(:user_job_posting, status: "none") }

    it "transitions and logs a pipeline step" do
      expect { user_job_posting.record_status_event!("apply") }.to change(PipelineStep, :count).by(1)
      expect(user_job_posting.reload.status).to eq("applied")
    end

    it "returns nil without raising when the transition is illegal" do
      user_job_posting.update!(status: "archived")

      expect(user_job_posting.record_status_event!("apply")).to be_nil
    end

    it "returns nil for an event outside the known transitions" do
      expect(user_job_posting.record_status_event!("delete_everything")).to be_nil
    end
  end
end
