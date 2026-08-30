# frozen_string_literal: true

# The question knowledge graph review surface (TASK-113 AC#2/#4/#5).
# Read-only except for the explicit human merge/split decisions -- nothing
# here fills or submits an answer.
class QuestionArchetypesController < ApplicationController
  before_action :set_archetype, only: %i[show merge split]
  helper_method :archetype_occurrences, :archetype_strategies, :merge_targets

  def index
    @overview = QuestionGraph::Overview.call
  end

  def show
    @recommendation = @archetype.recommended_handling
  end

  def merge
    target = QuestionArchetypes::Merge.call(source: @archetype, target: merge_target)
    redirect_to question_archetype_path(target), notice: "Merged into #{target.label}."
  rescue ArgumentError => e
    redirect_to question_archetype_path(@archetype), alert: e.message
  end

  def split
    new_archetype = run_split
    redirect_to question_archetype_path(new_archetype), notice: "Split off #{new_archetype.label}."
  rescue ArgumentError => e
    redirect_to question_archetype_path(@archetype), alert: e.message
  end

  private

  def run_split
    QuestionArchetypes::Split.call(archetype: @archetype, occurrence_ids: params[:occurrence_ids],
                                   label: params[:label])
  end

  def merge_target
    QuestionArchetype.find(params.expect(:target_id))
  end

  def set_archetype
    @archetype = QuestionArchetype.find(params.expect(:id))
  end

  def archetype_occurrences
    @archetype_occurrences ||=
      @archetype.question_occurrences.includes(:job_posting, :user_job_posting).order(observed_at: :desc)
  end

  def archetype_strategies
    @archetype_strategies ||= @archetype.answer_strategies.order(:persona_id, version: :desc)
  end

  def merge_targets
    @merge_targets ||= QuestionArchetype.active.where.not(id: @archetype.id).order(:label)
  end
end
