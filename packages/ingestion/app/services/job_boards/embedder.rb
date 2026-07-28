# frozen_string_literal: true

class JobBoards::Embedder
  # Using local llama.cpp / v1 API endpoint
  API_URL = "#{ENV.fetch('OLLAMA_API_BASE', 'http://localhost:11500/v1')}/embeddings".freeze

  def initialize(job_posting)
    @job_posting = job_posting
  end

  def call(force: false)
    return unless enabled?
    return if @job_posting.body.blank? && @job_posting.title.blank?

    # Shield: Do not process embeddings for expired/stale jobs unless forced
    return if @job_posting.expired? && !force

    # Construct text for embedding
    raw_text = "Title: #{@job_posting.title}\nCompany: #{@job_posting.company}\nDescription: #{@job_posting.body&.truncate(3000)}"
    input_text = Guardrails::Normalizer.new(raw_text).call

    response = Faraday.post(API_URL) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        input: input_text,
        model: "local" # Server alias — decoupled from GGUF filename
      }.to_json
    end

    if response.success?
      data = JSON.parse(response.body)
      embedding = data.dig("data", 0, "embedding") || data["embedding"]

      if embedding
        @job_posting.update!(embedding: embedding)
        true
      else
        Rails.logger.error "[Embedder] No embedding found in response: #{response.body}"
        false
      end
    else
      handle_error(response)
      false
    end
  rescue ActiveRecord::ConnectionTimeoutError => e
    Rails.logger.error "[Embedder] Database connection timeout: #{e.message}. Skipping embedding for Job #{@job_posting.id}."
    false
  rescue StandardError => e
    Rails.logger.error "[Embedder] Exception for Job #{@job_posting.id}: #{e.message}"
    false
  end

  # Utility to embed a query string for semantic search
  def self.embed_text(text)
    return nil unless new(nil).send(:enabled?)

    input_text = Guardrails::Normalizer.new(text).call

    response = Faraday.post(API_URL) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        input: input_text,
        model: "local"
      }.to_json
    end

    return nil unless response.success?

    data = JSON.parse(response.body)
    data.dig("data", 0, "embedding") || data["embedding"]
  end

  private

  def enabled?
    return false if ENV["ENABLE_EMBEDDINGS"] == "false"

    true
  end

  def handle_error(response)
    if response.status == 501
      Rails.logger.warn "[Embedder] Local LLM server does not support embeddings. " \
                        "Fix: Restart llama-server with the `--embeddings` flag. " \
                        "To suppress this warning, set ENABLE_EMBEDDINGS=false"
    else
      Rails.logger.error "[Embedder] API Error: #{response.status} - #{response.body}"
    end
  end
end
