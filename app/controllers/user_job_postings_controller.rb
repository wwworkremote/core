# frozen_string_literal: true

class UserJobPostingsController < ApplicationController
  before_action :set_job_posting, only: %i[create analyze_match generate_artifacts]

  # COALESCE rather than plain applied_at: rows tracked before that column
  # existed have no date, and ordering on a bare NULL drops them all to one end
  # regardless of direction. Falling back to created_at sorts them by when we
  # learned of them, which is the honest approximation.
  SORTS = {
    "newest" => Arel.sql("COALESCE(applied_at, created_at) DESC"),
    "oldest" => Arel.sql("COALESCE(applied_at, created_at) ASC")
  }.freeze

  # The overview intentionally materializes one ordered collection so its
  # columns and summary cards agree on the same funnel snapshot.
  # rubocop:disable-next Metrics/AbcSize
  def index
    scoped = sorted_tracked_postings
    @tracked = scoped.to_a
    @funnel_stats = funnel_stats(@tracked)
    @favorites = @tracked.select { |record| record.status == "favorited" }
    @applied = @tracked.select { |record| record.status == "applied" }
  end

  def create
    build_user_job_posting
    apply_status_event
    apply_manual_outcome
    redirect_back_or_to(job_posting_path(@job_posting), notice: "Job status updated.")
  end

  def update
    @user_job_posting = current_user.user_job_postings.find(params.expect(:id))
    return unless @user_job_posting.update(user_job_posting_params)

    redirect_back_or_to(user_job_postings_path, notice: "Job record updated.")
  end

  def destroy
    @user_job_posting = current_user.user_job_postings.find(params.expect(:id))
    @user_job_posting.destroy
    redirect_back_or_to(user_job_postings_path, notice: "Job removed from your list.")
  end

  def analyze_match
    result = LLM::ProfileMatcher.call(current_user, @job_posting, force: forced?)
    flash_llm_result(result, success: "AI alignment scan complete.", failure: "Scan failed")
    redirect_back_or_to(job_posting_path(@job_posting))
  end

  def generate_artifacts
    result = LLM::ArtifactGenerator.call(current_user, @job_posting, force: forced?)
    flash_llm_result(result, success: "Bespoke application artifacts generated and appended to notes.",
                             failure: "Generation failed")
    redirect_back_or_to(job_posting_path(@job_posting))
  end

  # Fixed vocabulary, not free text -- the same values the backfill importers
  # write (see bin/import_indeed_applications, bin/import_linkedin_tracker),
  # so a manually-logged rejection and an imported one render identically.
  # "manual" as outcome_source still lets a later import overwrite this if a
  # stronger automated signal shows up. "offered" lives here, not on status
  # -- see the comment on UserJobPosting's aasm block (TASK-82/TASK-94).
  MANUAL_OUTCOMES = %w[rejected reviewed closed offered].freeze

  private

  def apply_status_event
    @user_job_posting.record_status_event!(params[:status]) if params[:status].present?
  end

  def apply_manual_outcome
    return unless MANUAL_OUTCOMES.include?(params[:outcome])

    @user_job_posting.update!(outcome: params[:outcome], outcome_at: Time.current, outcome_source: "manual")
  end

  def sorted_tracked_postings
    current_user.user_job_postings.includes(:job_posting, :application_field_answers).order(SORTS.fetch(sort_key))
  end

  # rubocop:disable-next Metrics/AbcSize
  def funnel_stats(records)
    { tracked: records.length, applied: records.count { |record| record.status == "applied" },
      personas: records.count { |record| record.resume_persona_id.present? },
      answers: records.sum { |record| record.application_field_answers.length },
      outcomes: records.count { |record| record.outcome.present? } }
  end

  def sort_key
    @sort = SORTS.key?(params[:sort]) ? params[:sort] : "newest"
  end

  def set_job_posting
    @job_posting = JobPosting.find(params.expect(:job_posting_id))
  end

  def build_user_job_posting
    @user_job_posting = current_user.user_job_postings.find_or_initialize_by(job_posting: @job_posting)
    assign_job_search_id
    @user_job_posting.save!
  end

  def assign_job_search_id
    @user_job_posting.job_search_id = params[:job_search_id] if params[:job_search_id].present?
  end

  def forced?
    params[:force] == "true"
  end

  def flash_llm_result(result, success:, failure:)
    if result[:success]
      flash[:notice] = success
    else
      flash[:alert] = "#{failure}: #{result[:error]}"
    end
  end

  # Deliberately excludes :status -- writing that column directly would skip
  # the AASM guards entirely. Status changes go through record_status_event!.
  # outcome/outcome_at/outcome_source ARE permitted here, but only to support
  # clearing a mistaken mark (the form posts all three as nil together) --
  # setting a real outcome goes through apply_manual_outcome's fixed
  # vocabulary in #create, not through arbitrary values on this action.
  def user_job_posting_params
    permitted = params.expect(user_job_posting: %i[notes outcome outcome_at outcome_source])
    permitted[:outcome].present? ? permitted.except(:outcome, :outcome_at, :outcome_source) : permitted
  end
end
