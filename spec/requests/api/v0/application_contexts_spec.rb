# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationContext" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }
  let(:source) do
    {
      "archetypes" => {
        "staff_platform" => {
          "short_label" => "Staff Platform", "title" => "Staff Platform Engineer",
          "target_tier" => "staff", "summary" => "Summary", "core_skills" => [],
          "featured_positions" => [], "additional_experience" => [], "selected_projects" => []
        }
      }, "positions" => {}
    }
  end

  before do
    allow(User).to receive(:first).and_return(user)
    allow(Resume::Source).to receive(:new).and_return(instance_double(Resume::Source, to_h: source))
    allow(ProfileContactFields).to receive(:call).with(user).and_return({ name: "Candidate" })
  end

  it "saves the selected canonical persona and personal snapshot on the application" do
    patch "/api/v0/job_postings/#{job_posting.id}/application_context",
          params: { persona_id: "staff_platform" }

    expect(response).to have_http_status(:ok)
    expect(UserJobPosting.last).to have_attributes(
      resume_persona_id: "staff_platform", application_profile_snapshot: { "name" => "Candidate" }
    )
    expect(response.parsed_body).to include("selected_persona_id" => "staff_platform")
  end

  it "carries one application from persona selection through field fill to applied" do
    patch "/api/v0/job_postings/#{job_posting.id}/application_context",
          params: { persona_id: "staff_platform" }

    post "/api/v0/job_postings/#{job_posting.id}/application_field_answers",
         params: { application_field_answer: {
           field_key: "workday:email:0", field_label: "Email", field_type: "email",
           answer: "candidate@example.com", answer_source: "profile",
           page_url: "https://example.myworkdayjobs.com/apply"
         } }

    post "/api/v0/job_postings/#{job_posting.id}/application_status",
         params: { event: "apply", link: "https://example.myworkdayjobs.com/completed" }

    get "/api/v0/job_postings/#{job_posting.id}/application_context"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(
      "selected_persona_id" => "staff_platform",
      "field_answers" => contain_exactly(include("field_key" => "workday:email:0",
                                                  "answer" => "candidate@example.com"))
    )
    expect(UserJobPosting.last.status).to eq("applied")
  end
end
