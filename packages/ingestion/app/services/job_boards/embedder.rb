# frozen_string_literal: true

class JobBoards::Embedder
  # Using local llama.cpp / v1 API endpoint
  API_URL = "#{ENV.fetch('OLLAMA_API_BASE', 'http://localhost:11500/v1')}/embeddings".freeze

  def initialize(job_posting)
    @job_posting = job_posting
  end

  def call(force: false)
    return unless should_embed?(force)

    perform_embedding?
  rescue StandardError => e
    log_failure(e)
    false
  end

  # Utility to embed a query string for semantic search
  def self.embed_text(text)
    return nil unless new(nil).send(:enabled?)

    response = post_embedding(text)
    return nil unless response.success?

    parse_embedding(response)
  end

  def self.post_embedding(text)
    input_text = Guardrails::Normalizer.new(text).call
    Faraday.post(API_URL) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = { input: input_text, model: "local" }.to_json # Server alias -- decoupled from GGUF filename
    end
  end

  def self.parse_embedding(response)
    data = JSON.parse(response.body)
    data.dig("data", 0, "embedding") || data["embedding"]
  end

  private

  def should_embed?(force)
    return false unless enabled?
    return false if @job_posting.body.blank? && @job_posting.title.blank?
    # Shield: Do not process embeddings for expired/stale jobs unless forced
    return false if @job_posting.expired? && !force

    true
  end

  def perform_embedding?
    response = self.class.post_embedding(embedding_source_text)
    return failed_response?(response) unless response.success?

    save_embedding?(response)
  end

  def failed_response?(response)
    handle_error(response)
    false
  end

  def embedding_source_text
    "Title: #{@job_posting.title}\nCompany: #{@job_posting.company}\nDescription: #{@job_posting.body&.truncate(3000)}"
  end

  def save_embedding?(response)
    embedding = self.class.parse_embedding(response)
    return missing_embedding_error?(response) unless embedding

    @job_posting.update!(embedding: embedding)
    true
  end

  def missing_embedding_error?(response)
    Rails.logger.error "[Embedder] No embedding found in response: #{response.body}"
    false
  end

  def log_failure(error)
    return log_timeout(error) if error.is_a?(ActiveRecord::ConnectionTimeoutError)

    Rails.logger.error "[Embedder] Exception for Job #{@job_posting.id}: #{error.message}"
  end

  def log_timeout(error)
    Rails.logger.error "[Embedder] Database connection timeout: #{error.message}. " \
                       "Skipping embedding for Job #{@job_posting.id}."
  end

  def enabled?
    ENV["ENABLE_EMBEDDINGS"] != "false"
  end

  def handle_error(response)
    return warn_embeddings_unsupported if response.status == 501

    Rails.logger.error "[Embedder] API Error: #{response.status} - #{response.body}"
  end

  def warn_embeddings_unsupported
    Rails.logger.warn "[Embedder] Local LLM server does not support embeddings. " \
                      "Fix: Restart llama-server with the `--embeddings` flag. " \
                      "To suppress this warning, set ENABLE_EMBEDDINGS=false"
  end
end
