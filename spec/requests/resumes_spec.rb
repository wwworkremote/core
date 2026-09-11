# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resumes" do
  let(:user) do
    User.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) do |u|
      u.name = ENV.fetch("ADMIN_NAME", "mike")
      u.password = ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end
  let!(:resume) { user.resumes.create!(name: "Backend Engineer", version: 1, content: {}) }

  describe "GET /resumes" do
    it "lists the current user's resumes" do
      get resumes_path
      expect(response).to be_successful
      expect(response.body).to include("Backend Engineer")
    end
  end

  describe "GET /resumes/:id" do
    it "shows the resume" do
      get resume_path(resume)
      expect(response).to be_successful
    end
  end

  describe "POST /resumes" do
    it "creates a resume and redirects" do
      expect {
        post resumes_path, params: { resume: { name: "New Resume", version: 1, content: "{}" } }
      }.to change(Resume, :count).by(1)

      expect(response).to redirect_to(resumes_path)
    end

    it "re-renders new on validation failure" do
      post resumes_path, params: { resume: { name: "", version: 1 } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /resumes/:id" do
    it "updates the resume and redirects" do
      patch resume_path(resume), params: { resume: { name: "Renamed" } }
      expect(response).to redirect_to(resume_path(resume))
      expect(resume.reload.name).to eq("Renamed")
    end

    it "re-renders edit on validation failure" do
      patch resume_path(resume), params: { resume: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /resumes/:id" do
    it "destroys the resume and redirects" do
      expect { delete resume_path(resume) }.to change(Resume, :count).by(-1)
      expect(response).to redirect_to(resumes_path)
    end
  end

  describe "POST /resumes/:id/fork" do
    it "creates a forked copy and redirects to it" do
      expect {
        post fork_resume_path(resume), params: { new_name: "Forked Copy" }
      }.to change(Resume, :count).by(1)

      expect(response).to redirect_to(resume_path(Resume.last))
    end
  end

  describe "GET /resumes/:id/diff" do
    it "diffs the resume against another version" do
      other = user.resumes.create!(name: "Backend Engineer", version: 2, content: {})

      get diff_resume_path(resume, other_id: other.id)

      expect(response).to be_successful
    end
  end

  describe "GET /resumes/:id/export" do
    it "exports the resume as markdown by default" do
      get export_resume_path(resume)
      expect(response).to be_successful
      expect(response.headers["Content-Disposition"]).to include("resume_v1.markdown")
    end
  end
end
