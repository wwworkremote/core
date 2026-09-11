# frozen_string_literal: true

# Resolves the canonical just3ws resume persona into the application-scoped
# context the extension can use. The selected snapshot is stored on the
# UserJobPosting so later canonical edits cannot rewrite an old application.
class Resume::PersonaContext
  def self.personas(source: nil)
    new(source: source).personas
  end

  def self.call(persona_id, source: nil)
    new(source: source).call(persona_id)
  end

  def initialize(source: nil)
    @source = source
  end

  def personas
    archetypes.map do |id, persona|
      { id: id, label: persona["short_label"], title: persona["title"],
        target_tier: persona["target_tier"], summary: persona["summary"] }
    end
  end

  # The snapshot intentionally gathers every source-backed section in one
  # value so the application can be reproduced after the canonical source
  # changes.
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def call(persona_id)
    persona = archetypes.fetch(persona_id.to_s) { raise KeyError, "Unknown resume persona: #{persona_id}" }

    {
      "id" => persona_id.to_s,
      "label" => persona["short_label"],
      "title" => persona["title"],
      "target_tier" => persona["target_tier"],
      "summary" => persona["summary"],
      "core_skills" => Array(persona["core_skills"]),
      "positions" => selected_positions(persona),
      "additional_experience" => resolve_ids(persona["additional_experience"]),
      "selected_projects" => resolve_ids(persona["selected_projects"])
    }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  private

  def source
    @source ||= Resume::Source.new.to_h
  end

  def archetypes
    source.fetch("archetypes")
  end

  def selected_positions(persona)
    Array(persona["featured_positions"]).filter_map do |entry|
      source.dig("positions", entry["id"])
    end
  end

  def resolve_ids(entries)
    Array(entries).filter_map { |entry| source.dig("positions", entry["id"]) || entry }
  end
end
