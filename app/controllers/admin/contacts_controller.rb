# frozen_string_literal: true

class Admin::ContactsController < Admin::ApplicationController
  def create
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
    @contact = @job_posting.contacts.create!(contact_params)
    redirect_to admin_job_posting_path(@job_posting), notice: "Contact added."
  end

  def destroy
    @contact = Contact.find(params.expect(:id))
    @job_posting = @contact.job_posting
    @contact.destroy
    redirect_to admin_job_posting_path(@job_posting), notice: "Contact removed."
  end

  private

  def contact_params
    params.expect(contact: %i[name email phone role relationship_type])
  end
end
