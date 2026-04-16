# frozen_string_literal: true

module JobBoards
  class Embedder
    # Using local llama.cpp / v1 API endpoint
    API_URL = "#{ENV.fetch('OLLAMA_API_BASE', 'http://localhost:8080/v1')}/embeddings".freeze

    def initialize(job_posting)
      @job_posting = job_posting
    end

    def call
      return if @job_posting.body.blank? && @job_posting.title.blank?

      # Construct text for embedding
      input_text = "Title: #{@job_posting.title}\nCompany: #{@job_posting.company}\nDescription: #{@job_posting.body&.truncate(3000)}"

      response = Faraday.post(API_URL) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          input: input_text,
          model: 'Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf' # Should match your local model
        }.to_json
      end

      if response.success?
        data = JSON.parse(response.body)
        embedding = data.dig('data', 0, 'embedding') || data['embedding']

        if embedding
          @job_posting.update!(embedding: embedding)
          true
        else
          Rails.logger.error "[Embedder] No embedding found in response: #{response.body}"
          false
        end
      else
        Rails.logger.error "[Embedder] API Error: #{response.status} - #{response.body}"
        false
      end
    rescue StandardError => e
      Rails.logger.error "[Embedder] Exception for Job #{@job_posting.id}: #{e.message}"
      false
    end

    # Utility to embed a query string for semantic search
    def self.embed_text(text)
      response = Faraday.post(API_URL) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {
          input: text,
          model: 'Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf'
        }.to_json
      end

      return nil unless response.success?

      data = JSON.parse(response.body)
      data.dig('data', 0, 'embedding') || data['embedding']
    end
  end
end
