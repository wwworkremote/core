# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Pipeline UX" do
  let(:user) { User.find_or_create_by!(email: "mike@just3ws.com") { |u| u.name = "Mike"; u.password = "password" } }
  let!(:job) { create(:job_posting, title: "Neural Engineer", company: "Cyberdyne", body: "We build Skynet.") }
  let!(:career_profile) { create(:career_profile, user: user, resume_text: "I am a high-level software architect.") }
  let!(:model) {
    Model.find_or_create_by!(model_id: "Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf") { |m|
      m.name = "Qwen 2.5 Coder 7B (Local)"; m.provider = "ollama"
    }
  }

  it "allows a user to favorite a job and run an alignment scan" do
    visit job_posting_path(job)

    # 1. Favorite the job
    click_on "MARK_AS_FAVORITE"
    expect(page).to have_text(/RECORD_FAVORITED/i)

    # 2. Run AI Match (Mocked)
    mock_output = "### AI ANALYSIS\n- **MATCH_CONFIDENCE**: 95%\n- **STRENGTHS**: Expert level."
    sse_body = "data: {\"choices\":[{\"delta\":{\"content\":#{mock_output.to_json}}}]}\n\ndata: [DONE]\n"
    stub_request(:post, "http://localhost:11500/v1/chat/completions")
      .to_return(status: 200, body: sse_body, headers: { "Content-Type" => "text/event-stream" })

    click_on "RUN_ALIGNMENT_SCAN"
    expect(page).to have_text(/AI alignment scan complete/i)
    expect(page).to have_text(/Expert level/i)

    # 3. Add a personal note
    fill_in "APPEND_PRIVATE_CONTEXT...", with: "I know the CTO here."
    click_on "SAVE_INTERNAL_NOTES"
    expect(page).to have_text(/Job record updated/i)
  end

  it "allows a user to move a job through the Research Pipeline" do
    # Transition the JobPosting itself to 'favorited' so 'Apply' becomes possible in Admin view
    job.favorite!
    visit job_posting_path(job)

    # Move to 'Apply'
    click_on "Apply"
    expect(page).to have_text(/Activity logged/i)
    expect(job.reload.status).to eq("applied")
  end
end
