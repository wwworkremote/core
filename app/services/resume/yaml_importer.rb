# frozen_string_literal: true

class Resume::YamlImporter
  # No longer reads the peer repo's working tree -- it consumes just3ws'
  # published /resume.json through Resume::Source. Freshness is therefore the
  # Jekyll build's job: the endpoint is only as current as the last build.
  def self.call(user, source: nil, url: nil)
    new(user, source: source, url: url).call
  end

  def initialize(user, source: nil, url: nil)
    @user = user
    @profile = user.career_profile || user.create_career_profile!
    @source = source
    @url = url
  end

  def call
    ActiveRecord::Base.transaction { import_all }
    { success: true }
  end

  private

  def import_all
    import_profile
    import_skills
    import_positions
  end

  def source
    @source ||= Resume::Source.new(url: @url).to_h
  end

  def import_profile
    data = source["profile"]
    return unless data

    @user.update!(name: data["name"])
    @profile.update!(contact_info: data["contact"], location_info: data["location"])
  end

  # CareerProfile#skills was a hand-typed list that had drifted out of date --
  # it still read "Solid Queue, Sidekiq, RSpec, OpenTelemetry" with no AI
  # category at all, which is why a screening question about AI tooling came
  # back naming Solid Queue as an AI tool. The prompt renders this string
  # verbatim, so whatever is missing here the model cannot know.
  def import_skills
    items = skill_items
    return if items.empty?

    @profile.update!(skills: items.join(", "))
  end

  def skill_items
    Array(source.dig("skills", "categories")).flat_map { |category| Array(category["items"]) }
  end

  def import_positions
    Hash(source["positions"]).each { |key, data| import_position(key, data) }
  end

  def import_position(key, data)
    return unless data

    exp = find_or_initialize_experience(key, data)
    exp.update!(position_attributes(data))
    import_highlights(exp, data)
  end

  # The document keys positions by the same slug the files were named after,
  # so external_id is stable across the move off disk.
  def find_or_initialize_experience(key, data)
    external_id = data["id"] || key
    @profile.work_experiences.find_or_initialize_by(external_id: external_id)
  end

  # compact_blank on the narrative half, not the whole hash: an absent YAML key
  # must not erase what's already on the record. Every position file carries
  # summary + highlights and none carries context/description/action/impact, yet
  # all 24 imported rows had those four populated from elsewhere -- so the
  # unguarded version nulled four fields on every row each time it ran, which is
  # the kind of loss you only notice long after the run that caused it.
  #
  # company_and_dates stays unguarded on purpose. Those keys are present in all
  # 27 files, and end_date is *meant* to write nil when a role is current
  # ("Present" parses to nil) -- compacting it would pin an ended role open.
  def position_attributes(data)
    company_and_dates(data).merge(narrative_fields(data).compact_blank)
  end

  def company_and_dates(data)
    { company_name: data.dig("company", "name"), location: data.dig("company", "location"),
      title: data["title"], employment_type: data["type"],
      start_date: parse_date(data["start_date"]), end_date: parse_date(data["end_date"]) }
  end

  # skills is the position's technology vocabulary and it was being dropped.
  # Measured against the corpus, 218 of 229 skill terms (95%) appear nowhere
  # else in that position's own summary or highlights -- C#, ASP.NET, MySQL,
  # Subversion, JWT Authentication exist in this key and nowhere else. Dropping
  # it left twenty years of named technologies unretrievable.
  def narrative_fields(data)
    { context: data["context"], description: data["description"], summary: data["summary"],
      action: data["action"], impact: data["impact"], scope: data["scope"],
      skills: Array(data["skills"]).join(", ") }
  end

  # Highlights feed WorkExperience#embeddable_text, but they live on their own
  # table -- so replacing them changes what the experience embeds without
  # touching a single attribute of the experience itself, and the model's
  # after_commit never fires. Enqueueing here covers that. The job is
  # idempotent! on the experience id, so the common case (parent fields
  # changed too, job already enqueued) collapses to one run.
  def import_highlights(exp, data)
    exp.experience_highlights.destroy_all
    highlight_rows(data).each { |row| exp.experience_highlights.create!(row) }
    Resume::WorkExperienceEmbeddingJob.perform_later(exp.id)
  end

  def highlight_rows(data)
    Array(data["highlights"]).map { |h| { label: h["label"], text: h["text"] } } + case_study_rows(data)
  end

  # A position file may carry a `case_study` block -- challenge, a set of
  # approach dimensions, and outcomes. It's the most specific evidence in the
  # file (the outcomes are the quantified ones) and none of it was read: the
  # importer only ever looked at `highlights`. Folded in as highlights rather
  # than written to a narrative column, because those columns are populated
  # from elsewhere and overwriting them would lose hand-written text.
  def case_study_rows(data)
    study = data["case_study"]
    return [] unless study.is_a?(Hash)

    [{ label: "Challenge", text: study["challenge"] }] +
      approach_rows(study) + outcome_rows(study)
  end

  def approach_rows(study)
    Array(study["cartography_approach"]).map { |d| { label: d["dimension"], text: d["detail"] } }
  end

  def outcome_rows(study)
    Array(study["outcomes"]).map { |o| { label: "Outcome", text: o } }
  end

  # to_s before anything else: a bare `start_date: 2025` in the YAML is an
  # Integer, not a String, and calling downcase on it raised. Because the whole
  # import runs in one transaction, that single unquoted year rolled back all 27
  # positions -- which is why phalanx-duel, wwworkremote and emr-bear had never
  # made it into the database and why re-running the import never helped.
  def parse_date(value)
    str = value.to_s
    return nil if str.blank? || str.casecmp?("present")

    parse_full_date(str) || parse_year_only(str)
  end

  # Handle "September 2018"
  def parse_full_date(str)
    Date.parse(str)
  rescue Date::Error
    nil
  end

  # Fallback for year only or other formats
  def parse_year_only(str)
    Date.new(str.to_i, 1, 1) if /^\d{4}$/.match?(str)
  end
end
