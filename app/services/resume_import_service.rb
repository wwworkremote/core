# frozen_string_literal: true

class ResumeImportService
  def initialize(user)
    @user = user
  end

  def from_url(url, name: "Imported Resume")
    # Fetch content from the URL (just3ws.github.io)
    # This is a stub for the actual fetching logic
    response = Faraday.get(url)
    return nil unless response.success?

    create_resume(url, name, parse_response(response.body, url))
  end

  private

  def create_resume(url, name, parsed_content)
    latest_version = @user.resumes.where(name: name).maximum(:version) || 0
    @user.resumes.create!(name: name, version: latest_version + 1, content: parsed_content,
                          imported_from_url: url, status: :active)
  end

  def parse_response(body, url)
    return fallback_content(body, url) unless json_source?(url)

    parse_json_content(body, url)
  end

  def json_source?(url)
    url.include?("just3ws.github.io") || url.end_with?(".json")
  end

  def parse_json_content(body, url)
    standardize_schema(JSON.parse(body))
  rescue JSON::ParserError
    fallback_content(body, url)
  end

  def fallback_content(body, url)
    { summary: "Imported from #{url}", raw_body: body.truncate(5000) }
  end

  # Standardize external schema (JSON Resume / custom) to internal JSONB format
  def standardize_schema(data)
    basics(data).merge(experience: data["experience"] || data["work"], education: data["education"],
                       skills_names: data["skills"]&.pluck("name")).compact
  end

  def basics(data)
    { name: data["name"] || data["basics"]&.[]("name"), summary: data["summary"] || data["basics"]&.[]("summary") }
  end
end
