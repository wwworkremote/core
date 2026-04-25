# frozen_string_literal: true

class Resume::ProfileEmbedder
  API_URL = "#{ENV.fetch('OLLAMA_API_BASE', 'http://localhost:8080/v1')}/embeddings".freeze

  def initialize(career_profile)
    @career_profile = career_profile
  end

  def call
    return unless enabled?

    # Construct structured text for the embedding
    input_text = build_profile_text

    response = Faraday.post(API_URL) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        input: input_text,
        model: "Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf"
      }.to_json
    end

    if response.success?
      data = JSON.parse(response.body)
      embedding = data.dig("data", 0, "embedding") || data["embedding"]

      if embedding
        @career_profile.update!(embedding: embedding)
        true
      else
        Rails.logger.error "[ProfileEmbedder] No embedding found in response"
        false
      end
    else
      Rails.logger.error "[ProfileEmbedder] API Error: #{response.status} - #{response.body}"
      false
    end
  rescue StandardError => e
    Rails.logger.error "[ProfileEmbedder] Exception: #{e.message}"
    false
  end

  private

  def build_profile_text
    experiences = @career_profile.work_experiences.order(start_date: :desc).map do |exp|
      "#{exp.title} at #{exp.company_name}: #{exp.summary} Impact: #{exp.impact}"
    end.join("\n")

    [
      "Experience Level: #{@career_profile.experience_level}",
      "Skills: #{@career_profile.skills}",
      "Goals: #{@career_profile.goals}",
      "Job History:\n#{experiences}",
      "Resume:\n#{@career_profile.resume_text&.truncate(2000)}"
    ].join("\n\n")
  end

  def enabled?
    ENV["ENABLE_EMBEDDINGS"] != "false"
  end
end
