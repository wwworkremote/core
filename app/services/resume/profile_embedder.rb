# frozen_string_literal: true

class Resume::ProfileEmbedder
  # See JobBoards::Embedder -- embeddings live on a separate llama-server
  # instance from the chat model (OLLAMA_API_BASE), not the same one.
  API_URL = "#{ENV.fetch('OLLAMA_EMBED_API_BASE', 'http://localhost:11501/v1')}/embeddings".freeze

  def initialize(career_profile)
    @career_profile = career_profile
  end

  def call
    return unless enabled?

    handle_response?(fetch_embedding)
  rescue StandardError => e
    Rails.logger.error "[ProfileEmbedder] Exception: #{e.message}"
    false
  end

  private

  def fetch_embedding
    Faraday.post(API_URL) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = { input: build_profile_text, model: "local" }.to_json
    end
  end

  def handle_response?(response)
    unless response.success?
      Rails.logger.error "[ProfileEmbedder] API Error: #{response.status} - #{response.body}"
      return false
    end

    apply_embedding?(extract_embedding(response))
  end

  def extract_embedding(response)
    data = JSON.parse(response.body)
    data.dig("data", 0, "embedding") || data["embedding"]
  end

  def apply_embedding?(embedding)
    return reject_missing_embedding? unless embedding

    @career_profile.update!(embedding: embedding)
    true
  end

  def reject_missing_embedding?
    Rails.logger.error "[ProfileEmbedder] No embedding found in response"
    false
  end

  def build_profile_text
    profile_text_sections.join("\n\n")
  end

  def profile_text_sections
    [
      "Experience Level: #{@career_profile.experience_level}", "Skills: #{@career_profile.skills}",
      "Goals: #{@career_profile.goals}", "Job History:\n#{work_experience_summary}",
      "Resume:\n#{resume_excerpt}"
    ]
  end

  def resume_excerpt
    @career_profile.resume_text&.truncate(2000)
  end

  def work_experience_summary
    @career_profile.work_experiences.order(start_date: :desc).map do |exp|
      "#{exp.title} at #{exp.company_name}: #{exp.summary} Impact: #{exp.impact}"
    end.join("\n")
  end

  def enabled?
    ENV["ENABLE_EMBEDDINGS"] != "false"
  end
end
