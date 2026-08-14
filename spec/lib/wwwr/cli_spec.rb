# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/wwwr")
require Rails.root.join("lib/wwwr/cli")

RSpec.describe Wwwr::CLI do
  subject(:cli) { described_class.new }

  describe "status" do
    it "prints a pipeline health summary" do
      expect { cli.run(["status"]) }.to output(/Job postings:/).to_stdout
    end
  end

  describe "postings" do
    it "lists postings matching the given filter" do
      create(:job_posting, title: "Remote Ruby Dev", data: { "remote" => true })
      create(:job_posting, title: "Onsite Ruby Dev", signature: "onsite-1")

      expect { cli.run(["postings", "--remote"]) }.to output(/Remote Ruby Dev/).to_stdout
      expect { cli.run(["postings", "--remote"]) }.not_to output(/Onsite Ruby Dev/).to_stdout
    end

    it "reports when no postings match" do
      expect { cli.run(["postings", "--company=Nobody"]) }.to output(/No postings match/).to_stdout
    end
  end

  describe "transition" do
    it "applies a legal event and logs a pipeline step" do
      posting = create(:job_posting, status: "none")

      cli.run(["transition", posting.id.to_s, "favorite"])

      expect(posting.reload.status).to eq("favorited")
      expect(posting.pipeline_steps.last.status).to eq("favorite")
    end

    it "refuses an illegal transition without raising" do
      posting = create(:job_posting, status: "purged")

      expect { cli.run(["transition", posting.id.to_s, "ignore"]) }.not_to raise_error
      expect(posting.reload.status).to eq("purged")
    end

    it "reports an unknown posting id instead of raising" do
      expect { cli.run(%w[transition 999999 favorite]) }.to output(/not found/).to_stdout
    end
  end
end
