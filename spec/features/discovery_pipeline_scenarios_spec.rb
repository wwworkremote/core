# frozen_string_literal: true

require "rails_helper"

# Live system spec — requires a running app with real browser and net connections.
# Excluded from the normal suite. Run explicitly:
#   bundle exec rspec spec/features/discovery_pipeline_scenarios_spec.rb --tag live
RSpec.describe "The Discovery & Ingestion Flow", :live, type: :system do
  before do
    driven_by :cuprite
  end

  scenario "Triggering a scraper results in real-time discovery telemetry" do
    JobBoards::Source.find_or_create_by!(slug: "cord", name: "Cord")

    # Mock the Syncer to prevent long-running ingestion in tests
    allow(JobBoards::Syncer).to receive(:new).and_return(double("Syncer", call: true))

    # 1. Pipeline Control
    visit data_fetchers_path

    row = find(".group", text: /\ACord\b/i, wait: 15)
    row.find("button", text: "FORCE").click

    expect(page).to have_text(/successfully/i, wait: 20)

    # 2. Live Telemetry
    visit admin_root_path

    DiscoveryLink.create!(board_name: "Cord", url: "https://cord.com/jobs/999", status: "pending")

    expect(page).to have_text(/DISCOVERED/i, wait: 15)
    expect(page).to have_text("Cord")

    # 3. Full Ingestion promotion
    create(:job_posting, title: "Neural Link Architect", company: "Cyberdyne",
                         source: JobBoards::Source.find_by(slug: "cord"))

    expect(page).to have_text(/INGESTED/i, wait: 15)
    expect(page).to have_text("Neural Link Architect")
  end
end
