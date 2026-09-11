# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobBoards::AuditJob do
  it "resolves JobBoards::Auditor (regression: bare `Auditor` NameError under compact class syntax)" do
    auditor = instance_double(JobBoards::Auditor, call: { fixed: 0 })
    allow(JobBoards::Auditor).to receive(:new).with(fix: true, limit: 100).and_return(auditor)

    described_class.perform_now

    expect(auditor).to have_received(:call)
  end
end
