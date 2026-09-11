# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: human_tasks
#
#  id              :bigint           not null, primary key
#  kind            :string           not null
#  payload         :jsonb            not null
#  proposed_by     :string           default("ai"), not null
#  resolution_note :text
#  resolved_at     :datetime
#  status          :string           default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  job_posting_id  :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_human_tasks_on_job_posting_id                      (job_posting_id)
#  index_human_tasks_on_job_posting_id_and_kind_and_status  (job_posting_id,kind,status)
#  index_human_tasks_on_status                              (status)
#  index_human_tasks_on_user_id                             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (job_posting_id => job_postings.id)
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe HumanTask do
  describe "associations" do
    it { is_expected.to belong_to(:job_posting) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }

    it "rejects a blank payload" do
      task = build(:human_task, payload: nil)

      expect(task).not_to be_valid
    end
  end

  describe "AASM transitions" do
    it "starts pending" do
      expect(build(:human_task)).to be_pending
    end

    it "approve! moves to approved and stamps resolved_at" do
      task = create(:human_task)

      task.approve!

      expect(task).to be_approved
      expect(task.resolved_at).to be_present
    end

    it "reject! moves to rejected and stamps resolved_at" do
      task = create(:human_task)

      task.reject!

      expect(task).to be_rejected
      expect(task.resolved_at).to be_present
    end

    it "does not allow approving twice" do
      task = create(:human_task, status: "approved")

      expect(task.may_approve?).to be false
    end
  end

  describe ".open" do
    it "only returns pending tasks" do
      pending_task = create(:human_task)
      create(:human_task, status: "approved")

      expect(described_class.open).to contain_exactly(pending_task)
    end
  end

  describe "#stale?" do
    it "is false for a freshly created task" do
      expect(create(:human_task)).not_to be_stale
    end

    it "is true once pending for more than 24 hours" do
      task = create(:human_task, created_at: 25.hours.ago)

      expect(task).to be_stale
    end

    it "is false once resolved, regardless of age" do
      task = create(:human_task, created_at: 25.hours.ago, status: "approved")

      expect(task).not_to be_stale
    end
  end

  describe ".stale" do
    it "only returns pending tasks older than the threshold" do
      stale_task = create(:human_task, created_at: 25.hours.ago)
      create(:human_task, created_at: 1.hour.ago)
      create(:human_task, created_at: 25.hours.ago, status: "approved")

      expect(described_class.stale).to contain_exactly(stale_task)
    end
  end
end
