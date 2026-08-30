# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationFieldMappings" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }

  before { allow(User).to receive(:first).and_return(user) }

  it "retains a semantic mapping with the current answer context" do
    application = create(:user_job_posting, user: user, job_posting: job_posting)
    create(:application_field_answer, user_job_posting: application, field_key: "workday:email:0")

    post "/api/v0/job_postings/#{job_posting.id}/application_field_mappings",
         params: { application_field_mapping: {
           field_key: "workday:email:0", field_label: "Email", semantic_key: "profile.email",
           semantic_label: "Personal email", source_kind: "profile", provider: "workday",
           page_step: "My Information", page_url: "https://example.workday.com/apply",
           page_title: "Application", element_fingerprint: "email-input-v1",
           element_descriptor: { tag: "input", label: "Email" }, context: { required: true, question_text: "Email" }
         } }

    expect(response).to have_http_status(:ok)
    expect(ApplicationFieldMapping.last).to have_attributes(
      field_key: "workday:email:0", semantic_key: "profile.email", source_kind: "profile",
      application_field_answer_id: application.application_field_answers.sole.id
    )
  end

  it "stamps the guided_session_token when the mapping came from a guided session" do
    post "/api/v0/job_postings/#{job_posting.id}/application_field_mappings",
         params: { guided_session_token: "gs_map99", application_field_mapping: {
           field_key: "workday:phone:0", field_label: "Phone", semantic_key: "profile.phone",
           source_kind: "profile", element_descriptor: {}, context: {}
         } }

    expect(ApplicationFieldMapping.last.guided_session_token).to eq("gs_map99")
  end

  it "keeps remapping history instead of overwriting the prior association" do
    expect do
      2.times do |index|
        post "/api/v0/job_postings/#{job_posting.id}/application_field_mappings",
             params: { application_field_mapping: {
               field_key: "workday:name:0", field_label: "Name",
               semantic_key: index.zero? ? "profile.first_name" : "profile.last_name",
               source_kind: "profile", element_descriptor: {}, context: {}
             } }
      end
    end.to change(ApplicationFieldMapping, :count).by(2)
  end
end
