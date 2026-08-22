# frozen_string_literal: true

require "yaml"

class Resume::YamlImporter
  DEFAULT_BASE_PATH = "/Users/mike/github.com/just3ws/just3ws.github.io/_data/resume"
  attr_reader :base_path

  def self.call(user, base_path: nil)
    new(user, base_path: base_path).call
  end

  def initialize(user, base_path: nil)
    @user = user
    @profile = user.career_profile || user.create_career_profile!
    @base_path = base_path || DEFAULT_BASE_PATH
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

  def import_profile
    data = load_yaml("profile.yml")
    return unless data

    @user.update!(name: data["name"])
    @profile.update!(contact_info: data["contact"], location_info: data["location"])
  end

  # skills.yml is the resume's real skills inventory, grouped into categories.
  # CareerProfile#skills was a hand-typed list that had drifted out of date --
  # it still read "Solid Queue, Sidekiq, RSpec, OpenTelemetry" with no AI
  # category at all, which is why a screening question about AI tooling came
  # back naming Solid Queue as an AI tool. The prompt renders this string
  # verbatim, so whatever is missing here the model cannot know.
  def import_skills
    data = load_yaml("skills.yml")
    return unless data

    items = Array(data["categories"]).flat_map { |category| Array(category["items"]) }
    return if items.empty?

    @profile.update!(skills: items.join(", "))
  end

  def import_positions
    Dir.glob(File.join(@base_path, "positions", "*.yml")).each { |file| import_position(file) }
  end

  def import_position(file)
    data = YAML.load_file(file)
    return unless data

    exp = find_or_initialize_experience(file, data)
    exp.update!(position_attributes(data))
    import_highlights(exp, data)
  end

  def find_or_initialize_experience(file, data)
    external_id = data["id"] || File.basename(file, ".yml")
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
    Array(data["highlights"]).map { |h| { label: h["label"], text: h["text"] } }
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

  def load_yaml(filename)
    path = File.join(@base_path, filename)
    return nil unless File.exist?(path)
    YAML.load_file(path)
  end
end
