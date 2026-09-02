# frozen_string_literal: true

# Rewrites a generated interview prep pack into its read-aloud form -- same
# sections, same claims, same recommendations, only the wording and layout
# change for speech. Runs as a second pass after LLM::InterviewPrepGenerator
# stores the human version, so the two stay content-identical. The standard
# is docs/interview-prep/tts-readable-documentation.md; the output is consumed
# per docs/interview-prep/tts-transform-prompt.md.
class LLM::InterviewPrepGenerator::SpokenRewriter
  SYSTEM_RULES = "You reformat an interview prep pack so a text-to-speech engine reads it " \
                 "cleanly aloud. You never change the content -- same sections in the same " \
                 "order, same claims, same recommendations -- only wording for speech and layout."

  TASK_INSTRUCTIONS = <<~RULES
    Rewrite the pack above for read-aloud. Keep every section, in order, and every claim and
    recommendation. Change only formatting and word choice for speech.

    Open with a YAML frontmatter block fenced by lines of exactly three dashes. It must be
    valid YAML -- put every string value in double quotes, since titles and hints contain
    colons and dashes:
      title: "the pack title, every word and acronym spelled out"
      pronunciation:
        "DSP": "D S P"
        "Basis": "BAY sis"
        (one line per proper noun or acronym a speech engine could stumble on)
      sections:
        - "The Setup"
        - "Domain Primer"
        (the ordered section names, each quoted)
      spoken_minutes: a bare number, your estimate at about one hundred fifty words per minute

    Then the pack, following these rules:
    - Spell out abbreviations and contractions everywhere, not just first use: "Senior" not
      "Sr.", "for example" not "e.g.", "that is" not "i.e.", "versus" not "vs.", "and so on"
      not "etc.", "and" not "&", "with" not "w/", "about" not "~", "percent" not "%",
      "React and JavaScript" not "React/JS", "then" or "leads to" not an arrow.
    - Expand every acronym in full on first use; the short form is fine afterward.
    - Write numbers as spoken: "one hundred nineteen thousand to one hundred sixty thousand
      dollars" not "[posted band]"; "under one hundred milliseconds" not "sub-100ms"; "ninety-
      ninth percentile" not "p99"; "four percent" not "4%". Ranges use the word "to".
    - No tables and no code blocks -- convert a table to a heading with a short bullet list.
    - No emoji. No bare URLs -- name the source instead.
    - One idea per sentence, around fifteen words. Front-load the point; put a caveat in its
      own sentence, not a nested parenthetical.
    - Markdown is headings and short bullet lists only.

    Output only the rewritten pack, starting with the frontmatter fence.
  RULES

  def self.call(human_pack)
    new(human_pack).call
  end

  def initialize(human_pack)
    @human_pack = human_pack
  end

  def call
    result = LLM::Orchestrator.call(untrusted_text: @human_pack, system_rules: SYSTEM_RULES,
                                    task_instructions: TASK_INSTRUCTIONS, model: rewriter_model)
    result[:success] ? unwrap_fence(result[:output]) : nil
  end

  private

  # Local models like to wrap the whole answer in a ```yaml / ``` fence even
  # when told not to. Strip one wrapping fence so the "---" frontmatter is the
  # first line, which is what UserJobPosting#spoken_pack_parts expects.
  def unwrap_fence(text)
    text.to_s.strip.sub(/\A```[a-z]*\n/, "").sub(/\n```\s*\z/, "")
  end

  # Same model the prep pack itself uses (LLM::Registry.model_for(:interview_prep)
  # -> primary when unset). A read-aloud rewrite is the same profile: prose Mike
  # reads, no PHI, no third-party text beyond what was already screened.
  def rewriter_model
    LLM::Registry.model_for(:interview_prep)
  end
end
