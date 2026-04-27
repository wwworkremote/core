# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin Company Management", type: :system do
  let!(:company) { create(:company, name: "Cyberdyne", ingestion_enabled: true) }
  let!(:job) { create(:job_posting, company: company, status: "none", title: "Liquid Metal Specialist") }

  it "allows an admin to toggle ingestion and cascades purges" do
    visit admin_companies_path

    expect(page).to have_text(/Cyberdyne/i)
    
    # 1. Pause Ingestion
    click_button "PAUSE_INGESTION"
    
    # Use specific selector and wait
    expect(page).to have_css(".alert-success", text: /Ingestion disabled for Cyberdyne/i, wait: 10)
    expect(page).to have_text(/OFFLINE/i)
    
    # Verify side-effect: cascade purge
    expect(job.reload.status).to eq("purged")

    # 2. Resume Ingestion
    click_button "RESUME_INGESTION"
    expect(page).to have_css(".alert-success", text: /Ingestion resumed for Cyberdyne/i, wait: 10)
    expect(page).to have_text(/ACTIVE_SYNC/i)
    
    company.reload
    expect(company.ingestion_enabled?).to be true
  end

  it "shows company details and job postings" do
    visit admin_company_path(company)
    expect(page).to have_text(/Cyberdyne/i)
    expect(page).to have_text(/Liquid Metal Specialist/i)
  end
end
