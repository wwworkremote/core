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
    if source_locked?(slug)
      Rails.logger.info "[JobBoards::Client] Skipping #{method.upcase} #{url} - #{slug} is currently locked."
      return nil
    end

    response = connection(headers).send(method, url, payload)

    if response.status == 429
      handle_rate_limit(response)
      return nil
    end

    response
  rescue Faraday::Error => e
    Rails.logger.error "[JobBoards::Client] Connection error for #{slug}: #{e.message}"
    nil
  end

  def connection(headers)
    Faraday.new do |conn|
      conn.headers = headers
      conn.adapter Faraday.default_adapter
    end
  end

  def handle_rate_limit(response)
    # Extract retry-after if available, default to 1 hour
    retry_after = response.headers['Retry-After']
    duration = if retry_after.present? && retry_after.to_i.positive?
                 retry_after.to_i.seconds
               else
                 1.hour
               end

    lock_source!(slug, duration: duration)
  end
end
