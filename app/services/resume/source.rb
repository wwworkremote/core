# frozen_string_literal: true

# just3ws publishes its whole `_data/resume` tree at /resume.json --
# `{{ site.data.resume | jsonify }}` -- so one request carries every section the
# importer used to open a separate file for. See docs/just3ws-interop-protocol.md
# section 2. Fetched once and memoised; the importer reads sections out of it.
class Resume::Source
  DEFAULT_URL = "http://just3ws.localhost/resume.json"

  def initialize(url: nil)
    @url = url || ENV.fetch("JUST3WS_RESUME_URL", DEFAULT_URL)
  end

  # Raises rather than returning a partial document: a half-import silently
  # half-overwrites a good profile, which is worse than not importing.
  def to_h
    @to_h ||= begin
      response = Faraday.get(@url)
      raise "just3ws resume endpoint #{@url} returned #{response.status}" unless response.success?

      JSON.parse(response.body)
    end
  end
end
