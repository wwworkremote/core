# frozen_string_literal: true

# Lets the Chrome extension record a lifecycle transition at the moment it
# actually happens -- the user is sitting on the ATS application page, not in
# the app, so requiring a trip back to the web UI is how "applied" never got
# recorded. Same path as the web UI: UserJobPosting#record_status_event!.
class Api::V0::ApplicationStatusesController < ApiController
  def show
    render json: status_payload(existing_or_new)
  end

  def create
    record = tracked_record
    logged = record.record_status_event!(params[:event], link: params[:link])

    render json: transition_payload(record, logged)
  end

  private

  def transition_payload(record, logged)
    status_payload(record).merge(success: logged.present?, captured_answers: capture_answers)
  end

  def tracked_record
    current_api_user.user_job_postings.find_or_create_by!(job_posting: job_posting)
  end

  # The answers the user actually typed into the ATS form, shipped alongside
  # the transition. Without this the lifecycle records only *that* something
  # was submitted -- the questions and what was said in reply die with the
  # page, so the next application asking the same thing starts from blank.
  # Returns how many rows were written, for the panel to report back.
  def capture_answers
    submitted_answers.count { |answer| store_answer(answer) }
  end

  def submitted_answers
    params.permit(answers: %i[question answer])
          .fetch(:answers, [])
          .reject { |answer| answer[:question].blank? || answer[:answer].blank? }
  end

  # Upsert, not create: the same question gets re-answered across revisits and
  # a duplicate row would just dilute the extension's fuzzy match. Unchanged
  # answers are left alone so re-marking doesn't relabel a `canned` answer the
  # user copied verbatim as if they'd written it themselves.
  def store_answer(answer)
    question = job_posting.application_questions
                          .find_or_initialize_by(user: current_api_user, question_text: answer[:question])
    return false if question.answer_text == answer[:answer]

    question.update!(answer_text: answer[:answer], answer_source: "submitted")
  end

  def status_payload(record)
    { job_posting_id: job_posting.id, status: record.status, available_events: record.available_status_events }
  end

  # An unsaved record reports the same `none` status and event set the user
  # would get on first save, so `show` needs no separate not-yet-tracked branch.
  def existing_or_new
    current_api_user.user_job_postings.find_by(job_posting: job_posting) || UserJobPosting.new
  end

  def current_api_user
    @current_api_user ||= User.first
  end

  def job_posting
    @job_posting ||= JobPosting.find(params.expect(:job_posting_id))
  end
end
