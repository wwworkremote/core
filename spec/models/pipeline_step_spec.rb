# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_steps
#
#  id             :bigint           not null, primary key
#  link           :string
#  note           :text
#  notes          :text
#  reason_tags    :jsonb            not null
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
require "rails_helper"

RSpec.describe PipelineStep do
  describe "associations" do
    it { is_expected.to belong_to(:job_posting) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many_attached(:artifacts) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }

    # `link` is rendered with link_to on the posting timeline and is written
    # from outside-the-app input (the admin note form, the Chrome extension),
    # so a non-http scheme here would be a clickable payload.
    it "accepts an http(s) link" do
      expect(build(:pipeline_step, link: "https://job-boards.greenhouse.io/acme/jobs/1")).to be_valid
    end

    it "accepts a blank link" do
      expect(build(:pipeline_step, link: nil)).to be_valid
    end

    it "rejects a javascript: link" do
      step = build(:pipeline_step, link: "javascript:alert(1)")

      expect(step).not_to be_valid
      expect(step.errors[:link]).to include("must be an http(s) URL")
    end
  end
end
