# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: guided_sessions
#
#  id                  :bigint           not null, primary key
#  phase               :string           default("intake"), not null
#  playback_position   :integer          default(0), not null
#  provider            :string           not null
#  purpose             :string           default("application_execution"), not null
#  session_token       :string           not null
#  source_url          :string           not null
#  started_at          :datetime         not null
#  status              :string           default("active"), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  scenario_id         :bigint
#  user_job_posting_id :bigint
#
# Indexes
#
#  index_guided_sessions_on_scenario_id          (scenario_id)
#  index_guided_sessions_on_session_token        (session_token) UNIQUE
#  index_guided_sessions_on_user_job_posting_id  (user_job_posting_id)
#
# Foreign Keys
#
#  fk_rails_...  (scenario_id => scenarios.id)
#  fk_rails_...  (user_job_posting_id => user_job_postings.id)
#
RSpec.describe GuidedSession do
  subject(:session) do
    described_class.create!(source_url: "https://boards.greenhouse.io/acme/jobs/42",
                            purpose: "application_execution", user_job_posting: user_job_posting)
  end

  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }
  let(:user_job_posting) { create(:user_job_posting, user: user, job_posting: job_posting) }

  it "links to a user_job_posting but does not require one" do
    expect(session.user_job_posting).to eq(user_job_posting)
    expect(described_class.create!(source_url: "https://x.test/j/1").user_job_posting).to be_nil
  end

  describe "#complete!" do
    before { allow(Scenarios::RecordComparison).to receive(:call) }

    it "proposes the implied apply transition as a pending HumanTask" do
      expect { session.complete! }.to change(HumanTask, :count).by(1)

      task = HumanTask.last
      expect(task).to have_attributes(kind: "submit_approval", status: "pending", proposed_by: "ai",
                                      job_posting_id: job_posting.id, user_id: user.id)
      expect(task.payload).to include("proposed_event" => "apply", "guided_session_token" => session.session_token)
    end

    it "never advances the UserJobPosting's own AASM state" do
      expect { session.complete! }.not_to(change { user_job_posting.reload.status })
    end

    it "is idempotent -- re-completing proposes nothing new" do
      session.complete!
      expect { session.complete! }.not_to change(HumanTask, :count)
    end

    it "proposes nothing when there is no linked application" do
      loose = described_class.create!(source_url: "https://x.test/j/1", purpose: "application_execution")
      expect { loose.complete! }.not_to change(HumanTask, :count)
    end

    it "proposes nothing when the application is already past 'apply'" do
      user_job_posting.update!(status: "applied")
      expect { session.complete! }.not_to change(HumanTask, :count)
    end
  end
end
