# frozen_string_literal: true

# Personal CLI: pipeline health, browsing postings with the same filter
# vocabulary as JobPostingsController, and pipeline status transitions.
# Split out of bin/wwwr (a five-line shim) only so it's requireable from
# a spec without shelling out.
class Wwwr::CLI
  # Same literal dispatch table Admin::PipelineStepsController already
  # uses -- reused directly so the CLI's valid events can't drift from
  # the web UI's.
  STATUS_EVENTS = Admin::PipelineStepsController::STATUS_EVENTS

  # Explicit literal-symbol dispatch, not dynamic send(argv[0]) -- same
  # reasoning as STATUS_EVENTS above: argv[0] only ever selects a key in
  # this fixed table, never becomes part of a method name itself.
  COMMANDS = {
    "status" => :print_status,
    "postings" => :print_postings,
    "transition" => :run_transition,
    "match" => :run_match
  }.freeze

  def run(argv)
    command, *rest = argv
    send(COMMANDS.fetch(command, :print_usage), rest)
  end

  private

  def print_usage(_args = [])
    puts "Usage: bin/wwwr status | bin/wwwr postings [filters] | bin/wwwr transition <id> <event>"
    puts "  filters: --company= --source-id= --role-family= --location= --remote --contract"
    puts "  events:  #{STATUS_EVENTS.keys.join(' ')}"
  end

  def print_status(_args = [])
    puts status_lines.join("\n")
  end

  def status_lines
    ["Job postings:      #{JobPosting.count}", "Sources:           #{JobBoards::Source.count}",
     "Pending documents: #{pending_documents_count}", "Pipelines paused:  #{SystemSetting.paused?}",
     "Queue error rate:  #{solid_queue_error_rate}%", Wwwr::QueueStatus.call]
  end

  def pending_documents_count
    JobBoards::Document.where(aasm_state: ["pending", nil]).count
  end

  def solid_queue_error_rate
    (SolidQueue::Job.failed.count.to_f / [SolidQueue::Job.count, 1].max * 100).round(2)
  end

  def run_transition(args)
    id, event = args
    posting = JobPosting.find_by(id: id)
    return puts "Posting ##{id} not found." unless posting

    apply_transition(posting, event)
  end

  def apply_transition(posting, event)
    bang, guard = STATUS_EVENTS[event]
    return unknown_event(event) unless bang
    return illegal_transition(posting, event) unless posting.public_send(guard)

    perform_transition(posting, bang, event)
  end

  def unknown_event(event)
    puts "Unknown event #{event.inspect}. Valid: #{STATUS_EVENTS.keys.join(', ')}"
  end

  def illegal_transition(posting, event)
    puts "Cannot transition ##{posting.id} (#{posting.status}) via #{event}."
  end

  # JobPosting#status and UserJobPosting#status are two AASM machines with
  # overlapping state names. This CLI and the admin UI drove the first; the
  # Chrome extension drives the second. Nothing reconciled them, so 25 rows
  # disagreed and one posting read as both "applied" and "ignored" -- which
  # makes every funnel number depend on which model you happen to query.
  #
  # record_status_event! is the extension's path and already does the guard,
  # the transition and the PipelineStep, so routing through it replaces the
  # hand-rolled step below rather than adding to it. Behaviour change worth
  # naming: ignore/expire aren't pipeline events on UserJobPosting, so they no
  # longer create a PipelineStep. They're properties of the posting, not of a
  # relationship to it, and 452 ignored postings would be noise in a pipeline.
  #
  # ponytail: keeps the two machines in step so recording an application today
  # is trustworthy either way. One owner for pipeline state is TASK-82.
  def perform_transition(posting, bang, event)
    posting.public_send(bang)
    User.sole.user_job_postings.find_or_create_by!(job_posting: posting).record_status_event!(event)
    puts "##{posting.id} #{posting.title.to_s.truncate(50)} -> #{event}"
  end

  def print_postings(args)
    postings = filtered_postings(parse_filters(args)).limit(20)
    return puts "No postings match." if postings.none?

    postings.each { |p| puts format_posting(p) }
  end

  def parse_filters(args)
    args.each_with_object({}) do |arg, filters|
      key, value = arg.delete_prefix("--").split("=", 2)
      filters[key.tr("-", "_").to_sym] = value.nil? || value
    end
  end

  def filtered_postings(filters)
    scope = apply_identity_filters(default_scope_for_cli, filters)
    apply_flag_filters(scope, filters)
  end

  # Matches JobPostingsController#base_job_postings's default: hide
  # ignored/purged/expired postings unless a status filter is given.
  def default_scope_for_cli
    JobPosting.recent.where.not(status: %w[ignored purged expired])
  end

  def apply_identity_filters(scope, filters)
    scope = filter_by(scope, :company_name, filters[:company])
    scope = filter_by(scope, :source_id, filters[:source_id])
    apply_text_filters(scope, filters)
  end

  def filter_by(scope, column, value)
    value ? scope.where(column => value) : scope
  end

  def apply_text_filters(scope, filters)
    scope = scope.by_role_family(filters[:role_family].to_sym) if filters[:role_family].is_a?(String)
    filters[:location].is_a?(String) ? scope.location_matches(filters[:location]) : scope
  end

  def apply_flag_filters(scope, filters)
    scope = scope.remote_only if filters[:remote]
    scope = scope.contract_only if filters[:contract]
    scope
  end

  def run_match(args) = args.first ? puts(Wwwr::Interop.call(args.first, parse_filters(args.drop(1)))) : print_usage

  def format_posting(posting)
    title = posting.title.to_s.truncate(45)
    company = company_label(posting).truncate(25)
    format("#%<id>-6d %<title>-46s %<company>-26s %<status>s",
           id: posting.id, title: title, company: company, status: posting.status)
  end

  def company_label(posting)
    posting.company.presence&.to_s || "Unknown"
  end
end
