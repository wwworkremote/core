# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V0::ApplicationStatus" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }

  # The controller resolves the actor as User.first (this is a single-user
  # system, same as Api::V0::ProfileController). Stub it rather than assuming
  # the factory user sorts first -- any stray row in the shared test DB would
  # otherwise silently point the request at a different user.
  before { allow(User).to receive(:first).and_return(user) }

  describe "GET show" do
    it "reports none with the events available to an untracked posting" do
      get "/api/v0/job_postings/#{job_posting.id}/application_status"

      expect(response.parsed_body).to include("status" => "none", "available_events" => %w[favorite apply])
    end

    it "reports the current status once the posting is tracked" do
      create(:user_job_posting, user: user, job_posting: job_posting, status: "applied")

      get "/api/v0/job_postings/#{job_posting.id}/application_status"

      expect(response.parsed_body["status"]).to eq("applied")
    end
  end

  describe "POST create" do
    it "marks a previously untracked posting as applied" do
      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }

      expect(response.parsed_body).to include("success" => true, "status" => "applied")
    end

    it "logs a pipeline step so the timeline matches a web-UI transition" do
      expect do
        post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }
      end.to change(PipelineStep, :count).by(1)
    end

    it "reports failure instead of raising when the transition is illegal" do
      create(:user_job_posting, user: user, job_posting: job_posting, status: "archived")

      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }

      expect(response.parsed_body).to include("success" => false, "status" => "archived")
    end

    it "refuses an event that is not a known transition" do
      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "delete_everything" }

      expect(response.parsed_body).to include("success" => false, "status" => "none")
    end

    it "records the application URL on the pipeline step" do
      post "/api/v0/job_postings/#{job_posting.id}/application_status",
           params: { event: "apply", link: "https://job-boards.greenhouse.io/acme/jobs/1" }

      expect(PipelineStep.last.link).to eq("https://job-boards.greenhouse.io/acme/jobs/1")
    end
  end

  # The half of the lifecycle that used to evaporate: the questions asked and
  # the answers actually sent lived only on the ATS page.
  describe "POST create with captured answers" do
    def apply_with(answers)
      post "/api/v0/job_postings/#{job_posting.id}/application_status",
           params: { event: "apply", answers: answers }
    end

    it "stores what the user typed, tagged as submitted rather than AI" do
      apply_with([{ question: "Why this role?", answer: "Because it's platform work." }])

      question = job_posting.application_questions.sole
      expect(question).to have_attributes(question_text: "Why this role?",
                                          answer_text: "Because it's platform work.",
                                          answer_source: "submitted")
    end

    it "reports how many answers it captured" do
      apply_with([{ question: "Why?", answer: "Reasons." }, { question: "Salary?", answer: "$1." }])

      expect(response.parsed_body["captured_answers"]).to eq(2)
    end

    it "updates the existing row instead of duplicating the question" do
      create(:application_question, user: user, job_posting: job_posting,
                                    question_text: "Why?", answer_text: "Old.", answer_source: "ai")

      expect { apply_with([{ question: "Why?", answer: "New." }]) }
        .not_to change(ApplicationQuestion, :count)
      expect(ApplicationQuestion.sole).to have_attributes(answer_text: "New.", answer_source: "submitted")
    end

    # Copying a canned answer verbatim into the form shouldn't relabel it as
    # something the user wrote -- provenance is what the badge is for.
    it "leaves an unchanged answer's source alone" do
      create(:application_question, user: user, job_posting: job_posting,
                                    question_text: "Why?", answer_text: "Same.", answer_source: "canned")

      apply_with([{ question: "Why?", answer: "Same." }])

      expect(ApplicationQuestion.sole.answer_source).to eq("canned")
      expect(response.parsed_body["captured_answers"]).to eq(0)
    end

    it "skips questions the user left blank" do
      expect { apply_with([{ question: "Optional?", answer: "" }]) }
        .not_to change(ApplicationQuestion, :count)
    end

    it "still transitions when no answers are sent at all" do
      post "/api/v0/job_postings/#{job_posting.id}/application_status", params: { event: "apply" }

      expect(response.parsed_body).to include("success" => true, "status" => "applied", "captured_answers" => 0)
    end
  end
end
