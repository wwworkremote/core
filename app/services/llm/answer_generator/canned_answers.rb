# frozen_string_literal: true

# Deterministic answers pulled directly from structured CareerProfile data --
# no LLM call, so these are instant and free. Each question is matched
# independently by keyword against the question text; a pattern matching but
# the underlying data being blank (e.g. no work_experiences at all) falls
# through to nil rather than erroring -- "not canned-answerable right now,"
# letting LLM::AnswerGenerator fall back to the AI path.
class LLM::AnswerGenerator::CannedAnswers
  PATTERNS = [
    {
      matcher: /(?=.*\byears?\b)(?=.*\bexperience\b)/i,
      # ponytail: earliest start_date to latest end_date (or today) --
      # doesn't exclude employment gaps or dedupe overlapping roles, so
      # it's an approximation, not a precise sum. Upgrade to
      # interval-merging if a real gap ever skews this meaningfully.
      answer: lambda { |profile|
        dates = profile.work_experiences.pluck(:start_date, :end_date)
        next nil if dates.empty?

        earliest = dates.filter_map(&:first).min
        latest = dates.filter_map { |_, end_date| end_date || Date.current }.max
        next nil unless earliest

        "#{((latest - earliest) / 365.25).round} years"
      }
    },
    {
      matcher: /\b(location|located|based)\b/i,
      answer: ->(profile) { profile.location_info&.dig("display") }
    },
    {
      matcher: /github|portfolio|code sample/i,
      answer: ->(profile) { profile.contact_info&.dig("github", "url") || profile.github_url }
    },
    {
      matcher: /linkedin/i,
      answer: ->(profile) { profile.contact_info&.dig("linkedin", "url") }
    }
  ].freeze

  def self.match(question_text, profile)
    return nil if profile.nil?

    pattern = PATTERNS.find { |candidate| candidate[:matcher].match?(question_text) }
    return nil unless pattern

    pattern[:answer].call(profile).presence
  end
end
