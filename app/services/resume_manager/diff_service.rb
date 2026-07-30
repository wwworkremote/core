# frozen_string_literal: true

class ResumeManager::DiffService
  def initialize(resume_a, resume_b)
    @resume_a = resume_a
    @resume_b = resume_b
  end

  def call
    {
      name_changed: name_changed?,
      version_diff: @resume_b.version - @resume_a.version,
      content_diff: calculate_content_diff
    }.merge(skills_diff)
  end

  private

  def skills_diff
    {
      skills_added: skill_names(@resume_b) - skill_names(@resume_a),
      skills_removed: skill_names(@resume_a) - skill_names(@resume_b)
    }
  end

  def name_changed?
    @resume_a.name != @resume_b.name
  end

  def skill_names(resume)
    resume.skills.pluck(:name)
  end

  # A simple structural diff of the JSONB content. In a real app, we might
  # use a library or more sophisticated deep-diff logic.
  def calculate_content_diff
    content_keys.each_with_object({}) { |key, diff| add_content_key_diff(diff, key) }
  end

  def add_content_key_diff(diff, key)
    diff[key] = { from: content_a[key], to: content_b[key] } if content_a[key] != content_b[key]
  end

  def content_keys
    (content_a.keys + content_b.keys).uniq
  end

  def content_a
    @resume_a.content || {}
  end

  def content_b
    @resume_b.content || {}
  end
end
