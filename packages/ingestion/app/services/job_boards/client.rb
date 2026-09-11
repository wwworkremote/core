# frozen_string_literal: true

class JobBoards::Client
  include ApiGuard

  attr_reader :slug

  def initialize(slug)
    @slug = slug
  end

  def get(url, params = {}, headers = {})
    execute_request(:get, url, params, headers)
  end

  def post(url, body = {}, headers = {})
    execute_request(:post, url, body, headers)
  end

  private

  def execute_request(method, url, payload, headers)
    return log_locked_skip(method, url) if source_locked?(slug)

    respond(fetch(method, url, payload, headers))
  rescue Faraday::Error => e
    log_connection_error(e)
  end

  def respond(response)
    return handle_rate_limit(response) if response.status == 429

    response
  end

  def fetch(method, url, payload, headers)
    connection(headers).send(method, url, payload)
  end

  def log_locked_skip(method, url)
    Rails.logger.info "[JobBoards::Client] Skipping #{method.upcase} #{url} - #{slug} is currently locked."
    nil
  end

  def log_connection_error(error)
    Rails.logger.error "[JobBoards::Client] Connection error for #{slug}: #{error.message}"
    nil
  end

  def connection(headers)
    Faraday.new do |conn|
      conn.headers = headers
      conn.adapter Faraday.default_adapter
    end
  end

  def handle_rate_limit(response)
    lock_source!(slug, duration: retry_after_duration(response))
    nil
  end

  # Extract retry-after if available, default to 1 hour
  def retry_after_duration(response)
    retry_after = response.headers["Retry-After"]
    return 1.hour unless retry_after.present? && retry_after.to_i.positive?

    retry_after.to_i.seconds
  end
end
