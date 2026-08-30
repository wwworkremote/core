# frozen_string_literal: true

# ADR 010 / datalake.md "Curation and prune": capture is greedy, prune is the
# selective step. The raw layer is the PII-bearing one, so a bundle becomes
# prune-eligible once its guided session is *curated* (materialized into a
# Scenario -- cheap structural extraction has run) and a short grace window
# has passed. "Reviewed" is satisfied at prune time: this service only ever
# reports on a dry run; deletion needs an explicit `prune: true`, so a human
# reads the curation report and chooses to act on it.
#
# ponytail: low-value detection is just "clean reference match, no comparison
# findings" for now -- add "founded no new archetype / signature" if the
# report proves too noisy.
class Datalake::Prune
  GRACE = 7.days
  PRUNABLE = %i[prune_first prune_eligible orphan].freeze
  LEDGER = Datalake::AssetStore::ROOT.parent.join("pruned.json")

  Row = Data.define(:session_token, :verdict, :reason, :bytes, :assets)

  def self.call(prune: false) = new(prune: prune).call

  # Was this session's bundle deleted by a prune run? Lets Datalake::Bundle
  # tell "pruned" apart from "never captured".
  def self.pruned?(session_token)
    LEDGER.exist? && JSON.parse(LEDGER.read).any? { |entry| entry["session_token"] == session_token }
  end

  def initialize(prune:)
    @prune = prune
  end

  def call
    rows = bundle_dirs.map { |dir| classify(dir) }
    rows.select { |row| PRUNABLE.include?(row.verdict) }.each { |row| purge(row) } if @prune
    rows
  end

  private

  def bundle_dirs
    root = Datalake::AssetStore::ROOT
    root.exist? ? root.children.select(&:directory?) : []
  end

  def classify(dir)
    token = dir.basename.to_s
    session = GuidedSession.find_by(session_token: token)
    verdict, reason = verdict_for(session)
    Row.new(session_token: token, verdict: verdict, reason: reason,
            bytes: dir_bytes(dir), assets: Datalake::AssetStore.new(token).summary[:assets])
  end

  def verdict_for(session)
    return [:orphan, "no guided session -- likely a deleted session or a test leak"] if session.nil?

    kept_reason(session).then { |reason| reason ? [:keep, reason] : prunable_verdict(session) }
  end

  def kept_reason(session)
    return "session #{session.status}, not completed" unless session.status == "completed"
    return "not curated -- no Scenario materialized yet" if session.scenario_id.nil?
    return "within the #{GRACE.inspect} grace window" if session.updated_at > GRACE.ago

    nil
  end

  def prunable_verdict(session)
    return [:prune_first, "curated, clean reference match, no comparison findings"] if low_value?(session)

    [:prune_eligible, "curated + grace elapsed"]
  end

  def low_value?(session)
    comparison = session.reference_comparisons.order(:ran_at).last
    comparison&.outcome == "ok" && !comparison.comparison_findings.exists?
  end

  def dir_bytes(dir)
    dir.children.select(&:file?).sum(&:size)
  end

  def purge(row)
    Datalake::AssetStore.new(row.session_token).purge!
    append_to_ledger(row)
  end

  def append_to_ledger(row)
    entries = ledger_entries << row.to_h.merge(pruned_at: Time.current.iso8601)
    LEDGER.write(JSON.pretty_generate(entries))
  end

  def ledger_entries
    LEDGER.exist? ? JSON.parse(LEDGER.read) : []
  end
end
