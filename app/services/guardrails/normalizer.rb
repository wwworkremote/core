# frozen_string_literal: true

class Guardrails::Normalizer
  def initialize(text)
    @text = text.to_s
  end

  def call
    # 1. Normalize encoding first to avoid ArgumentError in blank? check
    normalized = @text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    return "" if normalized.blank?

    # 2. Replace null bytes with space (to prevent joining words)
    normalized.tr!("\u0000", " ")

    # 3. Collapse pathological whitespace
    # First collapse spaces
    normalized.gsub!(/[ \t]{2,}/, " ")

    # Then collapse excessive newlines (more than 2 -> 2)
    normalized.gsub!(/\n{3,}/, "\n\n")

    normalized.strip
  end
end
