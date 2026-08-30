# frozen_string_literal: true

# ADR 010 / TASK-123 read contract: the read-only view of one guided session's
# raw datalake bundle. Every consumer (the question graph, trace evidence,
# topology findings) reads raw assets **through Bundle, never File.read on the
# path** -- so the storage layout can change without touching consumers.
#
# Bundle knows nothing about what anyone extracts. It parses manifest.json,
# lists asset entries, and hands back sha256-verified bytes on request.
class Datalake::Bundle
  class Error < StandardError
  end

  Asset = Data.define(:seq, :type, :event_id, :sha256, :bytes, :captured_at) do
    def screenshot? = type == "screenshot"
  end

  def self.for(session_token) = new(session_token)

  def initialize(session_token)
    @token = session_token
    @store = Datalake::AssetStore.new(session_token)
    @dir = Datalake::AssetStore::ROOT.join(session_token)
  end

  # A guided session produced a bundle. Distinct from #pruned? -- a consumer
  # that finds neither knows the session simply never captured anything.
  def present? = @dir.join("manifest.json").exist?

  def pruned? = Datalake::Prune.pruned?(@token)

  def assets(type: nil, event_id: nil)
    all_assets.select { |asset| matches?(asset, type, event_id) }
  end

  def all_assets
    manifest["assets"].map { |entry| to_asset(entry) }
  end

  def gaps = manifest["gaps"]

  # The only way a consumer reads asset bytes. Raises on a manifest/file
  # mismatch -- a corrupt or tampered bundle should fail loudly, not feed a
  # silent extraction.
  def read(seq)
    entry = asset_entry(seq)
    bytes = @dir.join(entry.fetch("path")).binread
    verify!(entry, bytes)
    bytes
  end

  private

  def matches?(asset, type, event_id)
    (type.nil? || asset.type == type.to_s) && (event_id.nil? || asset.event_id == event_id)
  end

  def manifest = @manifest ||= @store.manifest

  def asset_entry(seq)
    manifest["assets"].find { |entry| entry["seq"] == seq } ||
      raise(Error, "no asset ##{seq} in bundle #{@token}")
  end

  def verify!(entry, bytes)
    actual = Digest::SHA256.hexdigest(bytes)
    return if actual == entry["sha256"]

    raise Error, "asset ##{entry['seq']} sha256 mismatch in bundle #{@token}"
  end

  def to_asset(entry)
    Asset.new(seq: entry["seq"], type: entry["type"], event_id: entry["guided_session_event_id"],
              sha256: entry["sha256"], bytes: entry["bytes"], captured_at: entry["captured_at"])
  end
end
