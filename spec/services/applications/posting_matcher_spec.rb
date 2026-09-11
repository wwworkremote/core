# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::PostingMatcher do
  it "matches on signature first" do
    posting = create(:job_posting, signature: "sig-1", company: "Acme", title: "Engineer")
    other = create(:job_posting, target_url: "https://example.com/jobs/1", company: "Acme", title: "Engineer")

    result = described_class.call(signature: "sig-1", native_id_fragment: "jobs/1",
                                  target_url: other.target_url, company: "Acme", title: "Engineer")

    expect(result).to eq(posting)
  end

  it "falls back to the native id fragment inside target_url" do
    posting = create(:job_posting, target_url: "https://boards.greenhouse.io/acme/jobs/12345")

    result = described_class.call(signature: "no-match", native_id_fragment: "/jobs/12345",
                                  target_url: nil, company: nil, title: nil)

    expect(result).to eq(posting)
  end

  it "falls back to the exact target_url" do
    posting = create(:job_posting, target_url: "https://example.com/jobs/99")

    result = described_class.call(signature: "no-match", native_id_fragment: "no-match-either",
                                  target_url: "https://example.com/jobs/99", company: nil, title: nil)

    expect(result).to eq(posting)
  end

  it "falls back to normalized company + title" do
    posting = create(:job_posting, company: "Files.com", title: "Staff Engineer", target_url: "https://x.com/1")

    result = described_class.call(signature: "no-match", native_id_fragment: "no-match",
                                  target_url: "https://different.com/1", company: " FILES.COM ",
                                  title: " staff engineer ")

    expect(result).to eq(posting)
  end

  it "does not match on title alone when company is blank" do
    create(:job_posting, company: "Acme", title: "Staff Engineer", target_url: "https://x.com/2")

    result = described_class.call(signature: "no-match", native_id_fragment: "no-match", target_url: "https://y.com",
                                  company: nil, title: "Staff Engineer")

    expect(result).to be_nil
  end

  it "returns nil when nothing matches" do
    result = described_class.call(signature: "no-match", native_id_fragment: "no-match", target_url: "https://z.com",
                                  company: "Nobody", title: "Nothing")

    expect(result).to be_nil
  end
end
