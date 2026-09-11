# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JobSearches" do
  let(:user) do
    User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) do |u|
      u.name = ENV.fetch("ADMIN_NAME", "mike")
      u.password = ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end
  let!(:job_search) { user.job_searches.create!(name: "Staff Ruby Roles") }

  describe "GET /job_searches" do
    it "lists the current user's job searches" do
      get job_searches_path
      expect(response).to be_successful
      expect(response.body).to include("Staff Ruby Roles")
    end
  end

  describe "GET /job_searches/:id" do
    it "shows the job search with its matches" do
      get job_search_path(job_search)
      expect(response).to be_successful
    end
  end

  describe "GET /job_searches/new" do
    it "renders the new form" do
      get new_job_search_path
      expect(response).to be_successful
    end
  end

  describe "GET /job_searches/:id/edit" do
    it "renders the edit form" do
      get edit_job_search_path(job_search)
      expect(response).to be_successful
    end
  end

  describe "POST /job_searches" do
    it "creates a job search and redirects" do
      expect {
        post job_searches_path, params: { job_search: { name: "Remote Rails Roles" } }
      }.to change(JobSearch, :count).by(1)

      expect(response).to redirect_to(job_searches_path)
    end

    it "re-renders new on validation failure" do
      post job_searches_path, params: { job_search: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /job_searches/:id" do
    it "updates the job search and redirects" do
      patch job_search_path(job_search), params: { job_search: { name: "Renamed Campaign" } }
      expect(response).to redirect_to(job_search_path(job_search))
      expect(job_search.reload.name).to eq("Renamed Campaign")
    end

    it "re-renders edit on validation failure" do
      patch job_search_path(job_search), params: { job_search: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /job_searches/:id" do
    it "destroys the job search and redirects" do
      expect { delete job_search_path(job_search) }.to change(JobSearch, :count).by(-1)
      expect(response).to redirect_to(job_searches_path)
    end
  end
end
