# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncDashboardJob, type: :job do
  it "calls JobBoards::Syncer" do
    syncer_double = instance_double(JobBoards::Syncer)
    expect(JobBoards::Syncer).to receive(:new).and_return(syncer_double)
    expect(syncer_double).to receive(:call)

    described_class.perform_now
  end
end
