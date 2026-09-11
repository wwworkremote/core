# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResumeManager::DiffService do
  subject(:diff) { described_class.new(resume_a, resume_b).call }

  let(:user) { create(:user) }
  let(:resume_a) { create(:resume, user: user, name: "Resume", version: 1, content: { summary: "A" }) }
  let(:resume_b) { create(:resume, user: user, name: "Resume", version: 2, content: { summary: "B" }) }

  it "flags whether the name changed" do
    expect(diff[:name_changed]).to be false
  end

  it "flags a name change" do
    resume_b.update!(name: "Different Resume", version: 3)
    expect(diff[:name_changed]).to be true
  end

  it "reports the version difference" do
    expect(diff[:version_diff]).to eq(1)
  end

  it "reports added and removed skills" do
    ruby = create(:skill, name: "Ruby")
    resume_a.skills = [ruby, create(:skill, name: "Rails")]
    resume_b.skills = [ruby, create(:skill, name: "Go")]

    expect(diff[:skills_added]).to eq(["Go"])
    expect(diff[:skills_removed]).to eq(["Rails"])
  end

  it "reports a structural diff of changed content keys" do
    expect(diff[:content_diff]).to eq("summary" => { from: "A", to: "B" })
  end

  it "includes keys present in only one side of the content diff" do
    resume_b.update!(content: { summary: "B", extra: "new" })
    expect(diff[:content_diff]).to eq(
      "summary" => { from: "A", to: "B" },
      "extra" => { from: nil, to: "new" }
    )
  end

  it "omits unchanged content keys from the diff" do
    resume_b.update!(content: { summary: "A" })
    expect(diff[:content_diff]).to eq({})
  end
end
