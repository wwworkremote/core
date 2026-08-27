# frozen_string_literal: true

# Applies a single pipeline/lifecycle event to a JobPosting from bin/wwwr
# transition. Split out of Wwwr::CLI to keep that class under
# Metrics/ClassLength -- this is a cohesive dispatch, not a bag of
# unrelated methods.
#
# Dispatches on which model actually owns the event -- same split as
# Admin::PipelineStepsController (TASK-82). "offer" is neither lifecycle
# nor pipeline: it's the employer's decision, recorded as an outcome, not
# a status transition on either model.
class Wwwr::TransitionRunner
  LIFECYCLE_EVENTS = Admin::PipelineStepsController::LIFECYCLE_EVENTS
  PIPELINE_EVENTS = Admin::PipelineStepsController::PIPELINE_EVENTS
  ALL_EVENTS = LIFECYCLE_EVENTS.keys + PIPELINE_EVENTS + ["offer"]

  def self.call(posting, event)
    new(posting, event).call
  end

  def initialize(posting, event)
    @posting = posting
    @event = event
  end

  # rubocop:disable-next Metrics/MethodLength, Metrics/AbcSize
  def call
    if LIFECYCLE_EVENTS.key?(event)
      apply_lifecycle_transition
    elsif event == "offer"
      apply_offer_outcome
    elsif PIPELINE_EVENTS.include?(event)
      apply_pipeline_transition
    else
      unknown_event
    end
  end

  private

  attr_reader :posting, :event

  # rubocop:disable-next Metrics/AbcSize
  def apply_lifecycle_transition
    bang, guard = LIFECYCLE_EVENTS[event]
    return illegal_transition(posting.status) unless posting.public_send(guard)

    posting.public_send(bang)
    announce
  end

  # record_status_event! does the guard, the transition, and the
  # PipelineStep in one call -- unlike the admin controller, the CLI has no
  # richer logger of its own, so this is the only PipelineStep this
  # transition needs.
  def apply_pipeline_transition
    tracked = tracked_posting
    return illegal_transition(tracked.status) unless tracked.record_status_event!(event)

    announce
  end

  def apply_offer_outcome
    tracked_posting.update!(outcome: "offered", outcome_at: Time.current, outcome_source: "manual")
    announce
  end

  def tracked_posting
    User.sole.user_job_postings.find_or_create_by!(job_posting: posting)
  end

  def announce
    puts "##{posting.id} #{posting.title.to_s.truncate(50)} -> #{event}"
  end

  def unknown_event
    puts "Unknown event #{event.inspect}. Valid: #{ALL_EVENTS.join(', ')}"
  end

  def illegal_transition(current_status)
    puts "Cannot transition ##{posting.id} (#{current_status}) via #{event}."
  end
end
