# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'The Discovery & Ingestion Flow', type: :system do
  before do
    driven_by :cuprite
    VCR.turn_off!(ignore_cassettes: true)
    WebMock.allow_net_connect!
  end

  scenario 'Triggering a scraper results in real-time discovery telemetry' do
    JobBoards::Source.find_or_create_by!(slug: 'cord', name: 'Cord')

    # Mock the Syncer to prevent long-running ingestion in tests
    allow(JobBoards::Syncer).to receive(:new).and_return(double('Syncer', call: true))

    # 1. Pipeline Control
    visit data_fetchers_path
    
    # We find the row specifically and click the button by its rendered text
    # The 'group' class is on the fetcher row. We ensure we have the right one.
    row = find('.group', text: /\ACord\b/i, wait: 15)
    row.find('button', text: 'FORCE').click

    # Wait for the flash message or the timestamp update
    expect(page).to have_content(/successfully/i, wait: 20)

    # 2. Live Telemetry
    visit admin_root_path
    
    # Simulate a background discovery event
    DiscoveryLink.create!(board_name: "Cord", url: "https://cord.com/jobs/999", status: "pending")
    
    # Check if the Discovery entry appears in the live feed
    expect(page).to have_content(/DISCOVERED/i, wait: 15)
    expect(page).to have_content('Cord')

    # 3. Full Ingestion promotion
    create(:job_posting, title: "Neural Link Architect", company: "Cyberdyne", source: JobBoards::Source.find_by(slug: 'cord'))
    
    expect(page).to have_content(/INGESTED/i, wait: 15)
    expect(page).to have_content('Neural Link Architect')

    puts "SCENARIO_SUCCESS: Discovery & Ingestion Flow verified."
  end
end
