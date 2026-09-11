# frozen_string_literal: true

require "rails_helper"

RSpec.describe Scenarios::TenantIdentifier do
  it "pulls the board slug from a path-slug provider URL" do
    expect(described_class.call("greenhouse", "https://boards.greenhouse.io/acme/jobs/4567")).to eq("acme")
    expect(described_class.call("lever", "https://jobs.lever.co/acme-co/abc-123")).to eq("acme-co")
  end

  it "pulls the tenant subdomain from a Workday URL" do
    expect(described_class.call("workday", "https://acme.wd5.myworkdayjobs.com/en-US/careers/job/123")).to eq("acme")
  end

  it "falls back to the bare host for an unrecognised provider" do
    expect(described_class.call("generic", "https://careers.acme.com/roles/42")).to eq("careers.acme.com")
    expect(described_class.call("generic", "https://www.acme.com/jobs/1")).to eq("acme.com")
  end

  it "returns nil for an unusable URL" do
    expect(described_class.call("greenhouse", "not a url")).to be_nil
    expect(described_class.call("greenhouse", nil)).to be_nil
  end
end
