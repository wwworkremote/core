# frozen_string_literal: true

require "rails_helper"

RSpec.describe InterviewProcess do
  let(:user) { create(:user) }
  let(:user_job_posting) { create(:user_job_posting, user: user, status: "applied") }

  describe "TEMPLATES" do
    it "only uses session types InterviewSession knows" do
      types = described_class::TEMPLATES.values.flatten.pluck(:session_type).uniq
      expect(types - InterviewSession::SESSION_TYPES).to be_empty
    end

    it "names the three shapes" do
      expect(described_class::TEMPLATE_NAMES).to contain_exactly(:standard_senior, :compressed, :staff)
    end
  end

  describe ".seed_default" do
    it "materializes the template's rounds as ordered, unscheduled sessions" do
      rounds = described_class.seed_default(user_job_posting, template: :compressed)

      expect(rounds.size).to eq(described_class::TEMPLATES[:compressed].size)
      expect(rounds.map(&:position)).to eq((1..rounds.size).to_a)
      expect(rounds).to all(have_attributes(scheduled_at: nil, outcome: "pending"))
      expect(rounds.first).to have_attributes(session_type: "Screening", notes: "Recruiter screen")
    end

    it "defaults to the standard_senior template" do
      rounds = described_class.seed_default(user_job_posting)
      expect(rounds.size).to eq(described_class::TEMPLATES[:standard_senior].size)
    end

    it "is a no-op when the posting already has sessions for this user" do
      described_class.seed_default(user_job_posting, template: :compressed)

      expect { described_class.seed_default(user_job_posting, template: :staff) }
        .not_to change(InterviewSession, :count)
    end

    it "raises on an unknown template" do
      expect { described_class.seed_default(user_job_posting, template: :nope) }
        .to raise_error(ArgumentError, /unknown template/)
    end

    it "does not advance the application on its own (no round is scheduled yet)" do
      described_class.seed_default(user_job_posting)
      expect(user_job_posting.reload.status).to eq("applied")
    end
  end

  describe ".in_flight_for" do
    it "returns one Progress per posting with a pending round, pointing at the current round" do
      described_class.seed_default(user_job_posting, template: :compressed)
      rounds = user_job_posting.job_posting.interview_sessions.ordered.to_a
      rounds.first.update!(scheduled_at: 1.day.from_now, outcome: "advanced")

      progress = described_class.in_flight_for(user).sole

      expect(progress.posting).to eq(user_job_posting.job_posting)
      expect(progress.current).to eq(rounds.second)
      expect(progress.position).to eq(2)
      expect(progress.total).to eq(rounds.size)
    end

    it "attaches the soonest pending InterviewTask for that posting" do
      described_class.seed_default(user_job_posting, template: :compressed)
      task = create(:interview_task, user: user, job_posting: user_job_posting.job_posting,
                                     status: "pending", due_at: 1.day.from_now)

      expect(described_class.in_flight_for(user).sole.next_task).to eq(task)
    end

    it "omits a process whose rounds are all resolved" do
      described_class.seed_default(user_job_posting, template: :compressed)
      user_job_posting.job_posting.interview_sessions.find_each do |s|
        s.update!(scheduled_at: 1.day.ago, outcome: "rejected")
      end

      expect(described_class.in_flight_for(user)).to be_empty
    end
  end
end
