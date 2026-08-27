# frozen_string_literal: true

# The task inbox: every open HumanTask an automated evaluator (a BPMN
# "Service Task", e.g. Pipeline::PersonaRecommender) has proposed and is
# waiting on a human to approve, edit, or reject. This is the actual
# "awaiting human" surface TASK-97 asked for -- PR-review style, showing the
# proposed content itself, not just a state name.
class Admin::HumanTasksController < Admin::ApplicationController
  def index
    @human_tasks = HumanTask.open.includes(:job_posting).order(created_at: :asc)
  end

  def approve
    task = HumanTask.find(params.expect(:id))
    apply_proposal(task) if task.kind == "persona_review"
    task.approve!
    redirect_to admin_human_tasks_path, notice: "Approved and applied."
  end

  def reject
    task = HumanTask.find(params.expect(:id))
    task.update!(resolution_note: params[:resolution_note])
    task.reject!
    redirect_to admin_human_tasks_path, notice: "Rejected."
  end

  private

  # Mirrors Api::V0::ApplicationContextsController#update -- same persona
  # -setting effect, triggered from the inbox instead of the extension panel.
  def apply_proposal(task)
    persona_id = task.payload["persona_id"]
    return if persona_id.blank? || persona_id == "none"

    context = Resume::PersonaContext.call(persona_id)
    user_job_posting_for(task).update!(resume_persona_id: context.fetch("id"), resume_persona_snapshot: context)
  end

  def user_job_posting_for(task)
    task.user.user_job_postings.find_or_create_by!(job_posting: task.job_posting)
  end
end
