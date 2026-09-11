# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobPostingTrendRollupJob do
  it "calls JobPostingTrendRollup" do
    allow(JobPostingTrendRollup).to receive(:call)

    described_class.perform_now

    expect(JobPostingTrendRollup).to have_received(:call)
  end
end
