# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Career Orchestration Loop", type: :system do
  let(:admin_user) { User.find_by(email: ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com")) || create(:user) }
  let!(:job_posting) {
    create(:job_posting, title: "Staff Ruby on Rails Engineer", body: "Deep Ruby and Rails expertise required.")
  }

  before do
    driven_by :cuprite
    VCR.turn_off!(ignore_cassettes: true)
    WebMock.allow_net_connect!
  end

  scenario "User synchronizes identity and analyzes a match" do
    # 1. Identity Synchronization
    # Mock YamlImporter to avoid absolute path dependency and slow sync
    allow(Resume::YamlImporter).to receive(:call) do |user, **_options|
      profile = user.career_profile || user.create_career_profile!
      profile.work_experiences.create!(
        title: "Staff Engineer",
        company_name: "Tech Corp",
        start_date: 5.years.ago,
        summary: "Expert Rubyist"
      )
      { success: true }
    end

    # Mock EmbeddingJob as it's now asynchronous
    allow(Resume::EmbeddingJob).to receive(:perform_later)

    visit career_profile_path
    click_button "SYNC_FROM_YAML", wait: 10

    # Verify sync by checking for content that should be in the DB after sync
    expect(page).to have_content(/Career Profile/i)

    # Wait for the record to be created in the background/transaction
    start_time = Time.current
    sleep 0.1 while WorkExperience.none? && (Time.current - start_time) < 5

    expect(WorkExperience.count).to be > 0

    # 2. Strategic Analysis
    visit job_posting_path(job_posting)

    # Mock LLM Match Analysis
    mock_analysis = "MATCH_CONFIDENCE: 92%"
    expect(LLM::Orchestrator).to receive(:call).at_least(:once).and_return({ success: true, output: mock_analysis })

    # Use a very specific button matcher
    click_button "RUN_ALIGNMENT_SCAN"
    expect(page).to have_content(/scan complete/i)
    expect(page).to have_content("MATCH_CONFIDENCE: 92%")

    # 3. Priority Recognition
    visit root_path
    expect(page).to have_content(job_posting.title)
    expect(page).to have_content(/HIGH_CONFIDENCE/i)
  end
end
