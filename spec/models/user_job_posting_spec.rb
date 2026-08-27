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
#  outcome_reason               :text
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

  describe ".idle" do
    let(:user) { create(:user) }

    def tracked(status: "applied", outcome: nil, job_status: "none", last_step_at: nil)
      job_posting = create(:job_posting, status: job_status)
      ujp = create(:user_job_posting, user: user, job_posting: job_posting, status: status, outcome: outcome)
      PipelineStep.create!(job_posting: job_posting, user: user, status: status,
                           created_at: last_step_at || (UserJobPosting::IDLE_AFTER.ago - 1.day))
      ujp
    end

    it "includes an active posting with no recent PipelineStep" do
      idle = tracked
      expect(described_class.idle).to include(idle)
    end

    it "excludes a posting with a recent PipelineStep" do
      fresh = tracked(last_step_at: 1.hour.ago)
      expect(described_class.idle).not_to include(fresh)
    end

    it "orders the most-neglected posting first" do
      recent = tracked(last_step_at: UserJobPosting::IDLE_AFTER.ago - 1.day)
      ancient = tracked(last_step_at: UserJobPosting::IDLE_AFTER.ago - 30.days)

      expect(described_class.idle.to_a).to eq([ancient, recent])
    end

    it "excludes status: none (never started)" do
      none = tracked(status: "none")
      expect(described_class.idle).not_to include(none)
    end

    it "excludes archived (Mike stopped)" do
      archived = tracked(status: "archived")
      expect(described_class.idle).not_to include(archived)
    end

    it "excludes a row with no PipelineStep at all when it was just created (e.g. a fresh import)" do
      job_posting = create(:job_posting)
      fresh_import = create(:user_job_posting, user: user, job_posting: job_posting, status: "applied")
      expect(described_class.idle).not_to include(fresh_import)
    end

    it "includes a row with no PipelineStep at all once it's old enough (created_at fallback)" do
      job_posting = create(:job_posting)
      old_import = create(:user_job_posting, user: user, job_posting: job_posting, status: "applied")
      old_import.update!(created_at: UserJobPosting::IDLE_AFTER.ago - 1.day)
      expect(described_class.idle).to include(old_import)
    end

    it "excludes a terminal outcome" do
      offered = tracked(outcome: "offered")
      expect(described_class.idle).not_to include(offered)
    end

    it "excludes a posting whose JobPosting is archived or expired" do
      dead_link = tracked(job_status: "expired")
      expect(described_class.idle).not_to include(dead_link)
    end
  end

  describe "#last_pipeline_activity_at" do
    it "returns the most recent PipelineStep's created_at for this user+posting" do
      ujp = create(:user_job_posting, status: "applied")
      PipelineStep.create!(job_posting: ujp.job_posting, user: ujp.user, status: "applied", created_at: 2.days.ago)
      PipelineStep.create!(job_posting: ujp.job_posting, user: ujp.user, status: "interview", created_at: 1.day.ago)

      expect(ujp.last_pipeline_activity_at).to be_within(1.second).of(1.day.ago)
    end

    it "falls back to created_at, never nil, when no PipelineStep exists" do
      ujp = create(:user_job_posting, status: "applied")
      expect(ujp.last_pipeline_activity_at).to eq(ujp.created_at)
    end
  end
end
