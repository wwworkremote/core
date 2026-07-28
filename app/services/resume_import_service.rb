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

    # Assume the URL returns JSON or Markdown that we can parse
    # For now, we'll store the raw response as content summary
    # and let the user refine it.
    parsed_content = parse_response(response.body, url)

    latest_version = @user.resumes.where(name: name).maximum(:version) || 0

    @user.resumes.create!(
      name: name,
      version: latest_version + 1,
      content: parsed_content,
      imported_from_url: url,
      status: :active
    )
  end

  private

  def parse_response(body, url)
    if url.include?("just3ws.github.io") || url.end_with?(".json")
      begin
        data = JSON.parse(body)
        # Standardize external schema to internal JSONB format
        {
          name: data["name"] || data["basics"]&.[]("name"),
          summary: data["summary"] || data["basics"]&.[]("summary"),
          experience: data["experience"] || data["work"],
          education: data["education"],
          skills_names: data["skills"]&.pluck("name")
        }.compact
      rescue JSON::ParserError
        { summary: "Imported from #{url}", raw_body: body.truncate(5000) }
      end
    else
      { summary: "Imported from #{url}", raw_body: body.truncate(5000) }
    end
  end
end
