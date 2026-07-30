# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncDashboardJob do
  it "calls JobBoards::Syncer" do
    syncer_double = instance_double(JobBoards::Syncer)
    allow(JobBoards::Syncer).to receive(:new).and_return(syncer_double)
    allow(syncer_double).to receive(:call)

    described_class.perform_now

    expect(JobBoards::Syncer).to have_received(:new)
    expect(syncer_double).to have_received(:call)
  end
end
