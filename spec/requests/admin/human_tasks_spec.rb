# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::HumanTasks" do
  let(:user) { create(:user) }
  let(:job_posting) { create(:job_posting) }
  let(:persona_source) do
    {
      "archetypes" => {
        "founding_staff_fullstack" => {
          "short_label" => "Founding Staff", "title" => "Founding Staff Engineer",
          "target_tier" => "early-stage", "summary" => "Summary", "core_skills" => [],
          "featured_positions" => [], "additional_experience" => [], "selected_projects" => []
        }
      }, "positions" => {}
    }
  end

  before do
    allow(Resume::Source).to receive(:new).and_return(instance_double(Resume::Source, to_h: persona_source))
  end

  describe "GET /admin/human_tasks" do
    it "lists only open tasks" do
      open_task = create(:human_task, job_posting: job_posting, user: user)
      create(:human_task, job_posting: job_posting, user: user, status: "approved")

      get admin_human_tasks_path

      expect(response).to have_http_status(:ok)
      expect(assigns(:human_tasks)).to contain_exactly(open_task)
    end

    it "orders open tasks oldest first" do
      newer = create(:human_task, job_posting: job_posting, user: user, created_at: 1.hour.ago)
      older = create(:human_task, job_posting: job_posting, user: user, created_at: 2.days.ago)

      get admin_human_tasks_path

      expect(assigns(:human_tasks)).to eq([older, newer])
    end
  end

  describe "POST /admin/human_tasks/:id/approve" do
    it "applies the proposed persona and resolves the task" do
      task = create(:human_task, job_posting: job_posting, user: user,
                                 payload: { "persona_id" => "founding_staff_fullstack" })

      post approve_admin_human_task_path(task)

      expect(response).to redirect_to(admin_human_tasks_path)
      expect(task.reload).to be_approved
      expect(user.user_job_postings.find_by(job_posting: job_posting).resume_persona_id)
        .to eq("founding_staff_fullstack")
    end

    it "does not apply anything when the proposal was 'none'" do
      task = create(:human_task, job_posting: job_posting, user: user, payload: { "persona_id" => "none" })

      post approve_admin_human_task_path(task)

      expect(task.reload).to be_approved
      expect(user.user_job_postings.find_by(job_posting: job_posting)).to be_nil
    end
  end

  describe "POST /admin/human_tasks/:id/reject" do
    it "resolves the task without touching the pipeline" do
      task = create(:human_task, job_posting: job_posting, user: user)

      post reject_admin_human_task_path(task), params: { resolution_note: "Wrong persona for this role." }

      expect(task.reload).to be_rejected
      expect(task.resolution_note).to eq("Wrong persona for this role.")
    end
  end
end
