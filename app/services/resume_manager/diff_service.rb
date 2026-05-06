# frozen_string_literal: true

module ResumeManager
  class DiffService
    def initialize(resume_a, resume_b)
      @resume_a = resume_a
      @resume_b = resume_b
    end

    def call
      {
        name_changed: @resume_a.name != @resume_b.name,
        version_diff: @resume_b.version - @resume_a.version,
        content_diff: calculate_content_diff,
        skills_added: @resume_b.skills.pluck(:name) - @resume_a.skills.pluck(:name),
        skills_removed: @resume_a.skills.pluck(:name) - @resume_b.skills.pluck(:name)
      }
    end

    private

    def calculate_content_diff
      # A simple structural diff of the JSONB content
      # In a real app, we might use a library or more sophisticated deep-diff logic
      a = @resume_a.content || {}
      b = @resume_b.content || {}

      all_keys = (a.keys + b.keys).uniq
      all_keys.each_with_object({}) do |key, diff|
        if a[key] != b[key]
          diff[key] = { from: a[key], to: b[key] }
        end
      end
    end
  end
end
