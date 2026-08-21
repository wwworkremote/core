# frozen_string_literal: true

# Assembles the screening-question-answer prompt for LLM::AnswerGenerator
# from a CareerProfile's structured experience, a JobPosting, and the
# question text -- mirrors LLM::ArtifactGenerator::PromptBuilder's shape.
class LLM::AnswerGenerator::PromptBuilder
  # Cap on how many experiences reach the prompt. Every experience used to be
  # sent on every question, so with a long history the two or three entries
  # that actually answered it were buried in twenty that didn't -- and the
  # model, told to use only the facts below, would answer from whatever was
  # nearest instead. Relevance-ranked, so the cap trims the irrelevant tail.
  MAX_EXPERIENCES = 8

  # Words shorter than this carry no signal ("the", "and", "you") and would
  # otherwise let boilerplate outscore a genuine topical match.
  MIN_SIGNIFICANT_WORD = 4

  # The length filter alone still lets "with"/"that"/"this"/"your" through,
  # and screening questions are dense in exactly those -- an experience full
  # of filler then outscores one that genuinely answers the question, which
  # is the bug this ranking exists to fix. Raising the length cap instead
  # isn't an option: it would also drop "Ruby", "Rails", "agent" and "skill".
  STOPWORDS = %w[
    that this with your what have from been were they them their there which
    when where about would could should into than then some more most such
    only also does doing done make made give given tell describe example
    specific something today part these those will just like other very
  ].to_set.freeze

  def self.call(...)
    new(...).call
  end

  def initialize(profile, job_posting, question_text)
    @profile = profile
    @job_posting = job_posting
    @question_text = question_text
  end

  def call
    <<~PROMPT
      [OBJECTIVE]
      Answer the following job application screening question in first
      person, as the candidate, using only facts supported by the
      candidate profile below.

      [QUESTION]
      #{@question_text}

      [CANDIDATE_PROFILE]
      Skills: #{@profile.skills}
      Goals: #{@profile.goals}
      History:
      #{experiences}

      [JOB_POSTING]
      Title: #{@job_posting.title}
      Company: #{@job_posting.company}

      [CONSTRAINTS]
      - 2-4 sentences, first person, no headers or markdown formatting.
      - Be specific and confident; don't hedge or pad with generic filler.
      - Do not fabricate facts not present in the profile above.
    PROMPT
  end

  private

  # Renders the same text the ranking searched over. Building a different
  # string here would mean an experience could be selected on words the model
  # never gets to see -- a match it can't then use is worse than no match.
  def experiences
    ranked_experiences.map { |exp| "- #{exp.embeddable_text}" }.join("\n")
  end

  # Semantic ranking when the experiences have been embedded, term overlap
  # when they haven't. Both paths are needed: embeddings are the only thing
  # that connects "MCP server tooling" to a question about "agentic
  # workflows" -- term overlap has no morphology, so it can't even connect
  # "servers" to "server" -- but a just-created entry has no embedding until
  # its job runs, and silently dropping it would be worse than ranking it
  # crudely.
  # An embedding service that's down must not take answer generation with it,
  # so any failure falls through to the lexical path rather than raising.
  def ranked_experiences
    semantically_ranked_experiences || lexically_ranked_experiences
  rescue StandardError => e
    Rails.logger.warn "[AnswerGenerator::PromptBuilder] Semantic ranking failed: #{e.message}"
    lexically_ranked_experiences
  end

  def semantically_ranked_experiences
    return nil if embedded_experiences.empty?

    question_embedding = VectorIntelligence.embed(@question_text)
    return nil if question_embedding.blank?

    nearest_experiences(question_embedding)
  end

  def nearest_experiences(question_embedding)
    embedded_experiences.nearest_neighbors(:embedding, question_embedding, distance: "cosine")
                        .limit(MAX_EXPERIENCES).to_a
  end

  def embedded_experiences
    @embedded_experiences ||= @profile.work_experiences.where.not(embedding: nil)
  end

  # Relevance first, recency as the tie-break. When nothing matches, every
  # score is 0 and this degrades cleanly to "the most recent MAX_EXPERIENCES"
  # -- the old behaviour, minus the tail. No separate no-match branch needed.
  def lexically_ranked_experiences
    @profile.work_experiences.sort_by { |exp| [-relevance(exp), -recency(exp)] }.first(MAX_EXPERIENCES)
  end

  # How much of the *question's* vocabulary this experience speaks to. Scored
  # against the question rather than normalised by length, so a long entry
  # can't win on verbosity alone.
  def relevance(experience)
    text = [experience.title, experience.company_name, experience.summary, experience.impact].join(" ")
    (significant_words(text) & question_words).size
  end

  def recency(experience)
    experience.start_date&.to_time.to_i
  end

  def question_words
    @question_words ||= significant_words(@question_text)
  end

  def significant_words(text)
    text.to_s.downcase.scan(/[a-z0-9]+/)
        .select { |word| word.length >= MIN_SIGNIFICANT_WORD && STOPWORDS.exclude?(word) }
        .to_set
  end
end
