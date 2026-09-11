# frozen_string_literal: true

require "rails_helper"

RSpec.describe WwworkRemote do
  it "publishes the release version used by integrations" do
    expect(described_class::VERSION).to eq("1.36.13")
  end
end
