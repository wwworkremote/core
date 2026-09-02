# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::InterviewPrepGenerator::PromptBuilder do
  let(:profile) { create(:career_profile, skills: "Ruby, Rails", goals: "Staff role") }
  let(:job) { create(:job_posting, title: "Sr Engineer", company_name: "Basis", body: "Build the DSP.") }

  before do
    create(:work_experience, career_profile: profile, title: "Architect", company_name: "OneMain",
                             summary: "Legacy modernization", impact: "Killed a 4% drop", start_date: 1.year.ago)
  end

  it "includes the posting, an experience, and the section instructions" do
    prompt = described_class.call(profile, job)

    expect(prompt).to include("Sr Engineer").and include("Basis").and include("Build the DSP.")
    expect(prompt).to include("Architect at OneMain")
    expect(prompt).to include("YOUR STORY").and include("NIGHT-BEFORE CHECKLIST")
  end

  it "instructs a posting-driven domain primer with learning resources and blind spots" do
    prompt = described_class.call(profile, job)

    expect(prompt).to include("DOMAIN PRIMER")
    expect(prompt).to include("blind spots")
    expect(prompt).to include("Verify links before relying on them")
  end

  it "names the linked referral contact when one exists" do
    create(:contact, job_posting: job, name: "Beep", role: "Staff Engineer", relationship_type: "former colleague")

    prompt = described_class.call(profile, job)

    expect(prompt).to include("Beep")
  end

  it "tells the model to omit the referral section when no contact is linked" do
    prompt = described_class.call(profile, job)

    expect(prompt).to include("omit the referral section")
  end

  it "folds in a prior match analysis when the user job posting has one" do
    user_job = create(:user_job_posting, job_posting: job, user: profile.user, match_analysis: "85% match, ruby-heavy")

    prompt = described_class.call(profile, job, user_job)

    expect(prompt).to include("85% match, ruby-heavy")
  end

  it "prefers an active PipelinePrompt override over the default" do
    PipelinePrompt.create!(key: "interview_prep_pack", name: "Prep", stage: "matching",
                           body: "CUSTOM PROMPT <%= job_posting.title %>")

    prompt = described_class.call(profile, job)

    expect(prompt).to include("CUSTOM PROMPT Sr Engineer")
    expect(prompt).not_to include("YOUR STORY")
  end
end
