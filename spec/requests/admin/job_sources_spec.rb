# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::JobSources" do
  describe "POST /admin/job_sources/:id/mark_not_interested" do
    it "ignores the source's untouched postings, leaving others alone" do
      source = create(:source)
      untouched = create(:job_posting, source: source, status: "none")
      favorited = create(:job_posting, source: source, status: "none")
      admin = User.find_by(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) ||
              User.create!(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com"), name: "mike", password: "password")
      create(:user_job_posting, user: admin, job_posting: favorited, status: "favorited")

      post mark_not_interested_admin_job_source_path(source)

      expect(response).to redirect_to(job_postings_path)
      expect(untouched.reload.status).to eq("ignored")
      expect(favorited.reload.status).to eq("none")
      expect(admin.user_job_postings.find_by(job_posting: favorited).status).to eq("favorited")
    end
  end
end
