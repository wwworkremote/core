# frozen_string_literal: true

# just3ws publishes its whole `_data/resume` tree at /resume.json --
# `{{ site.data.resume | jsonify }}` -- so one request carries every section the
# importer used to open a separate file for. See docs/just3ws-interop-protocol.md
# section 2. Fetched once and memoised; the importer reads sections out of it.
class Resume::Source
  # https, not http: nginx 301s http -> https for just3ws.localhost and Faraday
  # does not follow redirects, so the http URL in the protocol doc fails.
  DEFAULT_URL = "https://just3ws.localhost/resume.json"

  # mkcert's root. Ruby ships its own CA bundle and does not consult the macOS
  # keychain, so a *.localhost endpoint fails verification unless we name it.
  LOCAL_CA = File.expand_path("~/.local/share/mkcert/rootCA.pem")

  def initialize(url: nil)
    @url = url || ENV.fetch("JUST3WS_RESUME_URL", DEFAULT_URL)
  end

  # Raises rather than returning a partial document: a half-import silently
  # half-overwrites a good profile, which is worse than not importing at all.
  def to_h
    @to_h ||= begin
      response = Faraday.new(ssl: ssl_options).get(@url)
      raise "just3ws resume endpoint #{@url} returned #{response.status}" unless response.success?

      JSON.parse(response.body)
    end
  end

  private

  def ssl_options
    return {} unless URI(@url).host.to_s.end_with?(".localhost") && File.exist?(LOCAL_CA)

    { ca_file: LOCAL_CA }
  end
end
