# frozen_string_literal: true

class JobFetchers::UrlResolver
  def self.resolve(url)
    new(url).resolve
  end

  def initialize(url)
    @url = url
  end

  def resolve
    case @url
    when /linkedin\.com/ then resolve_linkedin
    when /indeed\.com/ then resolve_indeed
    when /adzuna\.com/ then resolve_adzuna
    else resolve_generic
    end
  end

  private

  def resolve_linkedin
    # Convert tracking/short URLs to canonical job view
    # Pattern: https://www.linkedin.com/jobs/view/123456789
    if @url =~ %r{jobs/view/(\d+)}
      "https://www.linkedin.com/jobs/view/#{::Regexp.last_match(1)}"
    elsif @url =~ %r{comm/jobs/view/(\d+)}
      "https://www.linkedin.com/jobs/view/#{::Regexp.last_match(1)}"
    else
      @url
    end
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

  def resolve_generic
    # Follow redirects to get the final destination

    response = Faraday.head(@url) do |req|
      req.options.timeout = 5
    end
    response.headers['location'] || @url
  rescue StandardError
    @url
  end
end
