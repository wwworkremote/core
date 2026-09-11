# frozen_string_literal: true

namespace :scenarios do
  desc "Preview a candidate Scenario against the provider reference; set PROMOTE=1 to explicitly replace it"
  task :reference_diff, [:scenario_token] => :environment do |_, args|
    candidate = Scenario.find_by!(scenario_token: args.fetch(:scenario_token))
    reference = ReferenceScenario.find_by(provider: candidate.provider)&.scenario
    diff = Scenarios::ReferenceDiff.call(candidate, reference: reference)

    puts JSON.pretty_generate(diff)
    next unless ENV["PROMOTE"] == "1"

    Scenarios::PromoteReference.call(candidate)
    puts "Promoted #{candidate.scenario_token} as #{candidate.provider} reference."
  end

  desc "Rebuild the Greenhouse sandbox Reference Scenario from a full execution guided session (ADR 009, TASK-118)"
  task build_sandbox_reference: :environment do
    abort "Refusing: sandbox reference is dev/test only (Rails.env.local?)." unless Rails.env.local?

    scenario = Scenarios::SandboxReferenceWalkthrough.call
    puts "Promoted #{scenario.scenario_token} as the greenhouse reference."
    scenario.scenario_signatures.order(:first_observed_at, :id).each do |signature|
      puts "  #{signature.kind} = #{signature.value}"
    end
  end

  # ── Real-extension browser dogfood (the one seam fixtures can't cover) ──────
  # Confirms the loaded Chrome extension, driving a real guided session against
  # the sandbox posting, produces the same marker shape SandboxReferenceWalkthrough
  # synthesises. `dogfood:start` hands you a URL to open; `dogfood:report` reads
  # back what the extension actually captured.
  namespace :dogfood do
    desc "Start a guided session against the sandbox posting; open the printed URL with the extension loaded"
    task start: :environment do
      abort "Refusing: dev/test only (Rails.env.local?)." unless Rails.env.local?
      Rake::Task["scenarios:build_sandbox_reference"].invoke unless ReferenceScenario.exists?(provider: "greenhouse")

      base = ENV.fetch("DOGFOOD_BASE", "http://wwworkremote.localhost:31000")
      session = GuidedSession.create!(source_url: "#{base}/sandbox/postings/1", purpose: "application_execution")
      puts <<~STEPS
        Guided session ##{session.id}  (token #{session.session_token})

        1. Load the extension unpacked from  #{Rails.root.join('extension')}
           (chrome://extensions → Developer mode → Load unpacked). A store build won't
           recognise the sandbox host.
        2. In that Chrome profile, open:
           #{session.tracked_source_url}
        3. Fill first name, last name, email, both questions, and pick a Gender option.
        4. Click "Submit Application" once. The extension pauses it — the page should NOT
           navigate to a confirmation. The in-page log says "paused before irreversible
           application submission".
        5. Open the session UI:  #{base}/guided_sessions/#{session.id}
           Approve the pending "Submission attempted" event, then click "Complete session".
        6. Report what was captured:
           bin/rails scenarios:dogfood:report[#{session.id}]
      STEPS
    end

    desc "Report what a sandbox dogfood guided session captured vs the greenhouse reference"
    task :report, [:session_id] => :environment do |_, args|
      session = GuidedSession.find(args.fetch(:session_id))
      # Read only -- never materialize here. The Scenario is built once, on
      # complete!, after the approval decision is final; materializing early
      # would freeze a stale approval_state into the signatures.
      if session.scenario.nil?
        abort "Not materialized yet — approve the pending event and click Complete session first."
      end

      reference = ReferenceScenario.find_by(provider: "greenhouse")&.scenario
      scenario = session.scenario
      comparison = session.latest_comparison

      puts "── Events (#{session.guided_session_events.count}) ─────────────────────────────"
      session.guided_session_events.order(:occurred_at, :id).each do |e|
        puts "  #{e.phase}/#{e.kind}  req=#{e.requirement} rev=#{e.reversibility} appr=#{e.approval_state}"
        fields = Array(e.evidence["fields"])
        fields.each { |f|
          puts "      field: #{f['field_key'].inspect} #{f['type']}/#{f['classification']} #{f['label'].inspect}"
        }
      end

      cand = scenario.scenario_signatures.order(:first_observed_at, :id).to_h { |s| [s.kind, s.value] }
      ref = reference ? reference.scenario_signatures.to_h { |s| [s.kind, s.value] } : {}
      puts "\n── Captured signatures (#{cand.size}) ────────────────────────────"
      cand.each { |k, v| puts "  #{k} = #{v}#{'   [only in this run]' unless ref.key?(k)}" }
      puts "\n── In reference but NOT captured ────────────────────────────"
      (ref.keys - cand.keys).each { |k| puts "  #{k} = #{ref[k]}" }

      puts "\n── Comparison ##{comparison&.id} (#{comparison&.outcome}) ────────────────────"
      if comparison&.outcome == "ok"
        cov = comparison.coverage.with_indifferent_access
        puts "  coverage: #{cov[:status]} #{cov[:reached]}/#{cov[:applicable]}"
        Array(cov[:checkpoints]).each { |c| puts "    #{c[:step] || c[:kind]}: #{c[:status]}" }
        comparison.comparison_findings.order(:category, :dimension, :locator).each do |f|
          puts "  finding: #{f.category}/#{f.dimension} #{f.locator} #{f.detail.to_h}"
        end
      end
      puts "\nPaste this whole block back."
    end
  end
end
