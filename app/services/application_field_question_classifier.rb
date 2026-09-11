# frozen_string_literal: true

# Stable, explainable first pass. Later AI classification can add evidence,
# but this baseline makes aggregate reports useful without a model call.
class ApplicationFieldQuestionClassifier
  TYPES = {
    "identity" => /first|middle|last|preferred|legal name|suffix|pronoun/i,
    "contact" => /email|phone|mobile|address|city|state|postal|zip|country/i,
    "eligibility" => /authorized|sponsor|work in|currently work|vanguard/i,
    "logistics" => /salary|start date|relocat|remote|travel|availability|notice/i,
    "experience" => /experience|years|skill|technology|language|framework|role|title|employer/i,
    "motivation" => /why|interest|interested|heard about|cover letter|learned/i,
    "demographic" => /gender|race|ethnicity|veteran|disab|voluntary/i
  }.freeze

  def self.call(label, type: nil)
    text = label.to_s.gsub(/\s+/, " ").strip
    kind = TYPES.find { |_name, pattern| text.match?(pattern) }&.first ||
           (type.to_s == "textarea" ? "free_text" : "other")
    { question_kind: kind, normalized_prompt: normalize(text) }
  end

  def self.normalize(text)
    text.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
  end
end
