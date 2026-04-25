# frozen_string_literal: true

class Quality::ContextBuilder
  # Returns a formatted string of architectural constraints for the given files.
  # This is intended to be injected into LLM prompts.
  def self.architectural_constraints_for(file_paths)
    insights = SystemInsight.active.where(file_path: Array(file_paths))
    return "" if insights.empty?

    sections = insights.group_by(&:tool).map do |tool, tool_insights|
      header = "### [#{tool.upcase}] Architectural Constraints"
      items = tool_insights.map do |i|
        severity = i.severity.upcase
        "[#{severity}] L#{i.line_number}: #{i.message}"
      end.join("\n")
      "#{header}\n#{items}"
    end.join("\n\n")

    <<~PROMPT
      ## SYSTEM_QUALITY_CONSTRAINTS
      The following issues were detected by static analysis tools.#{' '}
      You MUST address or maintain compliance with these constraints in your response:

      #{sections}
    PROMPT
  end

  # Returns similar insights using vector search
  def self.semantic_constraints_for(query_text, limit: 5)
    # This requires the embedding to be populated
    # SystemInsight.nearest_neighbors(:embedding, embedding, distance: "cosine").limit(limit)
    ""
  end
end
