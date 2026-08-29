# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::ComparisonRules do
  it "exposes a frozen version string" do
    expect(described_class::VERSION).to be_a(String).and be_frozen
  end
end
