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
    ActiveRecord::Base.transaction do
      import_profile
      import_positions
      # Add other imports (skills, etc.) as needed
    end
    { success: true }
  end

  private

  def import_profile
    data = load_yaml("profile.yml")
    return unless data

    @user.update!(name: data["name"])
    @profile.update!(contact_info: data["contact"], location_info: data["location"])
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

  def position_attributes(data)
    company_and_dates(data).merge(narrative_fields(data))
  end

  def company_and_dates(data)
    { company_name: data.dig("company", "name"), location: data.dig("company", "location"),
      title: data["title"], employment_type: data["type"],
      start_date: parse_date(data["start_date"]), end_date: parse_date(data["end_date"]) }
  end

  def narrative_fields(data)
    { context: data["context"], description: data["description"], summary: data["summary"],
      action: data["action"], impact: data["impact"], scope: data["scope"] }
  end

  def import_highlights(exp, data)
    exp.experience_highlights.destroy_all
    Array(data["highlights"]).each do |h|
      exp.experience_highlights.create!(label: h["label"], text: h["text"])
    end
  end

  def parse_date(str)
    return nil if str.blank? || str.downcase == "present"

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
