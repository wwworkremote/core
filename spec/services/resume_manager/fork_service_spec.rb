# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeManager::ForkService do
  subject(:fork_service) { described_class.new(original_resume) }

  let(:user) { create(:user) }
  let(:original_resume) do
    Resume.create!(
      user: user,
      name: "Original",
      version: 1,
      content: { summary: "Senior Dev" },
      status: :active
    )
  end

  describe "#call" do
    it "creates a new resume with incremented version" do
      forked = fork_service.call
      expect(forked.name).to eq("Original")
      expect(forked.version).to eq(2)
      expect(forked.parent_id).to eq(original_resume.id)
      expect(forked.content).to eq(original_resume.content)
    end

    it "creates a new resume track with version 1 if name changes" do
      forked = fork_service.call(new_name: "New Track")
      expect(forked.name).to eq("New Track")
      expect(forked.version).to eq(1)
      expect(forked.parent_id).to eq(original_resume.id)
    end
  end
end
