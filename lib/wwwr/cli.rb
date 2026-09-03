# frozen_string_literal: true

# Personal CLI: pipeline health, browsing postings with the same filter
# vocabulary as JobPostingsController, and pipeline status transitions.
# Split out of bin/wwwr (a five-line shim) only so it's requireable from
# a spec without shelling out.
class Wwwr::CLI
  # Explicit literal-symbol dispatch, not dynamic send(argv[0]) -- same
  # reasoning as STATUS_EVENTS above: argv[0] only ever selects a key in
  # this fixed table, never becomes part of a method name itself.
  COMMANDS = {
    "status" => :print_status,
    "postings" => :print_postings,
    "transition" => :run_transition,
    "match" => :run_match,
    "interview-prep" => :run_interview_prep,
    "help" => :print_help,
    "--help" => :print_help,
    "-h" => :print_help
  }.freeze

  HELP = {
    "interview-prep" => <<~TXT
      bin/wwwr interview-prep <job_posting_id> [--regenerate] [--spoken] [--export[=<role>]]

        Print or generate the interview prep pack for a posting. Two versions,
        same content: a human version and a read-aloud version for text-to-speech.

        (no flags)      print the stored human pack, or generate one if none exists
        --regenerate    force a fresh generation (rewrites both versions)
        --spoken        print the read-aloud version instead of the human one
        --export        write pack.md + pack.spoken.md to
                        ~/ai/outbox/wwwr/interview-prep/<role>/
        --export=<role> use <role> as the subdirectory name (default: company slug)

        Docs: docs/interview-prep/README.md
              docs/architecture/interview-prep-tooling.md (diagrams)
    TXT
  }.freeze

  def run(argv)
    command, *rest = argv
    send(COMMANDS.fetch(command, :print_usage), rest)
  end

  private

  def print_usage(_args = [])
    puts "Usage: status | postings [filters] | transition <id> <event> | match <id> --source=<n> [--escalate]"
    puts "       interview-prep <id> [--regenerate] [--spoken] [--export[=<role>]]"
    puts "       help [<command>]"
    puts "  filters: --company= --source-id= --role-family= --location= --remote --contract"
    puts "  events:  #{Wwwr::TransitionRunner::ALL_EVENTS.join(' ')} (match contract: docs/agents/interop.md)"
  end

  def print_help(args)
    topic = HELP[args.first]
    topic ? puts(topic) : print_usage
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

    Wwwr::TransitionRunner.call(posting, event)
  end

  def run_interview_prep(args)
    posting = JobPosting.find_by(id: args.first)
    return puts "Posting ##{args.first} not found." unless posting

    puts Wwwr::InterviewPrep.call(posting, **interview_prep_flags(args))
  end

  def interview_prep_flags(args)
    export = args.find { |a| a.start_with?("--export") }
    { regenerate: args.include?("--regenerate"), spoken: args.include?("--spoken"),
      export: export && (export.split("=", 2)[1] || true) }
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
