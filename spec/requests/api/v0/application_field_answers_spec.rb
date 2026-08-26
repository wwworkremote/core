# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationFieldAnswers" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }

  before { allow(User).to receive(:first).and_return(user) }

  describe "GET index" do
    it "returns the fields already provided for the application" do
      application = create(:user_job_posting, user: user, job_posting: job_posting)
      create(:application_field_answer, user_job_posting: application, field_key: "email")

      get "/api/v0/job_postings/#{job_posting.id}/application_field_answers"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.first).to include("field_key" => "email")
    end
  end

  describe "POST create" do
    let(:payload) do
      {
        application_field_answer: {
          field_key: "email", field_label: "Email", field_type: "email",
          answer: "mike@example.com", answer_source: "profile",
          page_url: "https://example.workday.com/apply"
        }
      }
    end

    it "records a field fill against the tracked application" do
      expect do
        post "/api/v0/job_postings/#{job_posting.id}/application_field_answers", params: payload
      end.to change(ApplicationFieldAnswer, :count).by(1)

      expect(response.parsed_body).to include("success" => true)
      expect(UserJobPosting.last.application_field_answers.sole).to have_attributes(
        field_key: "email", answer: "mike@example.com", answer_source: "profile"
      )
    end

    it "upserts a repeated fill for the same field" do
      post "/api/v0/job_postings/#{job_posting.id}/application_field_answers", params: payload
      changed = payload.deep_dup
      changed[:application_field_answer][:answer] = "updated@example.com"

      expect do
        post "/api/v0/job_postings/#{job_posting.id}/application_field_answers", params: changed
      end.not_to change(ApplicationFieldAnswer, :count)

      expect(ApplicationFieldAnswer.sole.answer).to eq("updated@example.com")
    end
  end
end
