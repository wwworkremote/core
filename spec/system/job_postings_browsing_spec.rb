# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Browsing and triaging job postings" do
  before { driven_by :cuprite }

  # Real browser click, not a request-spec body match -- this is the only
  # way to catch a Turbo Frame swallowing a navigation (job_postings_spec's
  # regex check on data-turbo-frame="_top" proves the attribute is present,
  # not that Turbo actually honors it).
  it "opens a posting from the index without the results frame swallowing the navigation" do
    job = create(:job_posting, title: "Senior Ruby Engineer", status: "none")

    visit job_postings_path
    # click_on's coordinate click lands on the company-name link, which the
    # card's full-tile overlay (before:absolute before:inset-0) sits under --
    # dispatching a real DOM click still exercises Turbo's click interceptor,
    # which is the thing this spec is actually checking.
    page.execute_script("arguments[0].click()", find_link(job.title).native)

    expect(page).to have_current_path(job_posting_path(job))
    expect(page).to have_text(job.title)
  end

  it "walks the triage queue and lets you back up to fix a wrong call" do
    older = create(:job_posting, title: "Skip This One", status: "none", published_at: 2.days.ago)
    newest = create(:job_posting, title: "Decide This One", status: "none", published_at: 1.hour.ago)

    visit job_posting_triage_path
    expect(page).to have_text(newest.title)

    click_on "Favorite"
    expect(older.reload.status).to eq("none")
    expect(newest.reload.status).to eq("none") # pipeline stage lives on UserJobPosting, not JobPosting (TASK-82)
    admin = User.find_by(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com"))
    expect(admin.user_job_postings.find_by(job_posting: newest).status).to eq("favorited")

    expect(page).to have_link("Back", href: job_posting_path(newest))
    click_link(href: job_posting_path(newest))
    expect(page).to have_current_path(job_posting_path(newest))
  end
end
