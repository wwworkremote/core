# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::PromoteReference do
  it "creates one provider pointer and replaces it only when explicitly called" do
    first = create(:scenario, provider: "greenhouse")
    second = create(:scenario, provider: "greenhouse")

    expect { described_class.call(first) }.to change(ReferenceScenario, :count).by(1)
    expect(ReferenceScenario.find_by(provider: "greenhouse").scenario).to eq(first)

    described_class.call(second)

    expect(ReferenceScenario.find_by(provider: "greenhouse").scenario).to eq(second)
    expect(ReferenceScenario.count).to eq(1)
  end
end
