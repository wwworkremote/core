# frozen_string_literal: true

# TASK-126 / ADR 010: the write side of the machine-local datalake. One
# directory per GuidedSession#session_token under a git-ignored repo path,
# with a manifest.json Rails owns. Stores raw guided-session assets (DOM, HAR,
# screenshots) keyed to the GuidedSessionEvent they were captured for.
#
# ponytail: read-modify-write of manifest.json with no cross-process lock --
# fine for one operator's browser; add flock if a second writer ever appears.
class Datalake::AssetStore
  ROOT = Rails.root.join("data/datalake/sessions")
  TYPES = %w[dom har screenshot dom_styles].freeze
  EXTENSIONS = { "dom" => ".html", "har" => ".har.json", "screenshot" => ".png", "dom_styles" => ".json" }.freeze

  def initialize(session_token)
    @token = session_token
    @dir = ROOT.join(session_token)
  end

  # Writes one asset file + a manifest entry. Returns the entry.
  def write_asset(type:, event_id:, bytes:)
    FileUtils.mkdir_p(@dir)
    seq = next_seq
    @dir.join(filename_for(seq, type)).binwrite(bytes)
    add_entry(:assets, asset_entry(seq: seq, type: type, event_id: event_id, bytes: bytes))
  end

  # Records that a capture was expected but did not land -- a cross-origin
  # frame, a closed shadow root, DevTools stealing the debugger, a POST that
  # failed. The session is never blocked by this.
  def write_gap(type:, event_id:, reason:)
    FileUtils.mkdir_p(@dir)
    add_entry(:gaps, { "guided_session_event_id" => event_id, "type" => type,
                       "reason" => reason.to_s.slice(0, 200), "at" => Time.current.iso8601 })
  end

  def manifest
    return default_manifest unless manifest_path.exist?

    JSON.parse(manifest_path.read)
  rescue JSON::ParserError
    default_manifest
  end

  # Shape of this bundle without reading the asset bytes -- for the sandbox
  # walkthrough and the (future) curation report.
  def summary
    data = manifest
    { asset_types: asset_types(data), assets: data["assets"].size, gaps: data["gaps"].size }
  end

  def asset_types(data = manifest)
    data["assets"].filter_map { |a| a["type"] }.uniq.sort
  end

  # Delete this session's whole raw bundle. The prune step (ADR 010) once it
  # is built; used now by tests and the sandbox walkthrough for cleanup.
  def purge!
    FileUtils.rm_rf(@dir)
  end

  private

  def manifest_path = @dir.join("manifest.json")

  def default_manifest
    { "session_token" => @token, "created_at" => Time.current.iso8601, "assets" => [], "gaps" => [] }
  end

  def next_seq
    (manifest["assets"].filter_map { |asset| asset["seq"] }.max || 0) + 1
  end

  def add_entry(key, entry)
    data = manifest
    data[key.to_s] << entry
    manifest_path.write(JSON.pretty_generate(data))
    entry
  end

  def asset_entry(seq:, type:, event_id:, bytes:)
    { "seq" => seq, "guided_session_event_id" => event_id, "type" => type, "path" => filename_for(seq, type),
      "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize, "captured_at" => Time.current.iso8601 }
  end

  def filename_for(seq, type)
    "#{format('%04d', seq)}-#{type}#{EXTENSIONS.fetch(type, '.bin')}"
  end
end
