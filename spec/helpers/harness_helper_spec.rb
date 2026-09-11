# frozen_string_literal: true

require "rails_helper"

RSpec.describe HarnessHelper do
  describe "#harness_badge" do
    it "is nil when there is no tracked application" do
      expect(helper.harness_badge(nil)).to be_nil
    end

    it "is nil when the application has never been through the harness" do
      application = instance_double(UserJobPosting, harness_state: :none)
      expect(helper.harness_badge(application)).to be_nil
    end

    it "returns [css, label] for a reached state" do
      application = instance_double(UserJobPosting, harness_state: :compared)
      css, label = helper.harness_badge(application)

      expect(css).to include("text-accent")
      expect(label).to eq("Harness: compared")
    end
  end
end
