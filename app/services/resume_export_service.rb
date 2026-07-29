# frozen_string_literal: true

class ResumeExportService
  def initialize(resume)
    @resume = resume
    @content = resume.content
  end

  def to_json(*_args)
    @content.merge(meta: json_meta).to_json
  end

  def to_markdown
    markdown_sections.compact.join("\n\n")
  end

  def to_text
    # Simple plain text conversion of markdown or direct from content
    to_markdown.gsub(/^#+ /, "").gsub("**", "")
  end

  def to_mcp
    # Return a structured format ideal for LLM context
    mcp_payload.to_json
  end

  def to_pdf
    # This usually requires a gem like wicked_pdf or grover.
    # For now, we return HTML that can be rendered to PDF.
    ApplicationController.render(
      template: "resumes/export",
      layout: "pdf",
      locals: { content: @content, skills: @resume.skills }
    )
  end

  private

  def json_meta
    { name: @resume.name, version: @resume.version, skills: @resume.skills.pluck(:name) }
  end

  def markdown_sections
    headline_and_summary + skills_section + experience_section + education_section
  end

  def headline_and_summary
    ["# #{@content['name'] || @resume.user.name}", @content["summary"]]
  end

  def skills_section
    ["## Skills", @resume.skills.pluck(:name).join(", ")]
  end

  def experience_section
    ["## Experience", render_experience]
  end

  def education_section
    ["## Education", render_education]
  end

  def mcp_payload
    { role: "resume", identifier: "#{@resume.name}_v#{@resume.version}", data: to_markdown,
      skills: @resume.skills.pluck(:name) }
  end

  def render_experience
    Array(@content["experience"]).map do |exp|
      "### #{exp['role']} at #{exp['company']}\n(#{exp['start_date']} - #{exp['end_date']})\n\n#{exp['description']}"
    end.join("\n\n")
  end

  def render_education
    Array(@content["education"]).map do |edu|
      "* **#{edu['degree']}**, #{edu['school']} (#{edu['year']})"
    end.join("\n")
  end
end
