# frozen_string_literal: true

class JobFetchers::UrlResolver
  RESOLVERS = {
    /linkedin\.com/ => :resolve_linkedin,
    /indeed\.com/ => :resolve_indeed,
    /adzuna\.com/ => :resolve_adzuna
  }.freeze

  def self.resolve(url)
    new(url).resolve
  end

  def initialize(url)
    @url = url
  end

  def resolve
    _pattern, handler = RESOLVERS.find { |pattern, _| pattern.match?(@url) }
    handler ? send(handler) : resolve_generic
  end

  private

  # Convert tracking/short URLs to canonical job view.
  # Pattern: https://www.linkedin.com/jobs/view/123456789 (optionally
  # prefixed with comm/ for the tracking-link variant).
  def resolve_linkedin
    match = @url.match(%r{(?:comm/)?jobs/view/(\d+)})
    match ? "https://www.linkedin.com/jobs/view/#{match[1]}" : @url
  end

  def resolve_indeed
    # Pattern: https://www.indeed.com/viewjob?jk=abcdef12345
    if @url =~ /jk=([a-zA-Z0-9]+)/
      "https://www.indeed.com/viewjob?jk=#{::Regexp.last_match(1)}"
    else
      @url
    end
  end

  def resolve_adzuna
    # Adzuna usually has the adref in the URL
    @url
  end

  # Follow redirects to get the final destination.
  def resolve_generic
    fetch_location || @url
  rescue StandardError
    @url
  end

  def fetch_location
    response = Faraday.head(@url) { |req| req.options.timeout = 5 }
    response.headers["location"]
  end
end
