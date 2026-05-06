# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contacts" do
  let!(:job) { create(:job_posting) }
  let(:contact_params) do
    {
      contact: {
        name: "John Doe",
        email: "john@example.com",
        role: "Recruiter"
      }
    }
  end

  describe "POST /admin/job_postings/:job_posting_id/contacts" do
    it "creates a new contact and redirects" do
      expect {
        post admin_job_posting_contacts_path(job), params: contact_params
      }.to change(Contact, :count).by(1)

      expect(response).to redirect_to(admin_job_posting_path(job))
      follow_redirect!
      expect(response.body).to include("Contact added.")
    end
  end

  describe "DELETE /admin/job_postings/:job_posting_id/contacts/:id" do
    let!(:contact) { create(:contact, job_posting: job) }

    it "destroys the contact and redirects" do
      expect {
        delete admin_job_posting_contact_path(job, contact)
      }.to change(Contact, :count).by(-1)

      expect(response).to redirect_to(admin_job_posting_path(job))
      follow_redirect!
      expect(response.body).to include("Contact removed.")
    end
  end
end
