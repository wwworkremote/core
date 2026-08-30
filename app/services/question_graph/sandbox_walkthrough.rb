# frozen_string_literal: true

# TASK-113 AC#7: a repeatable proof that duplicate observations aggregate onto
# one archetype without losing per-application provenance. Records the same two
# questions against two throwaway applications, then reports the invariants.
# Idempotent -- re-running reuses the fixtures and adds no rows.
class QuestionGraph::SandboxWalkthrough
  PROMPTS = ["Why do you want to work here?", "Are you authorized to work in the US?"].freeze
  SLUGS = %w[qg-sandbox-alpha qg-sandbox-beta].freeze

  def self.call = new.call

  def call
    applications = SLUGS.map { |slug| application_for(slug) }
    applications.each { |application| record_all(application) }
    report(applications)
  end

  private

  def user
    @user ||= User.find_or_create_by!(email: "mike@just3ws.com") { |u| u.password = "password" }
  end

  def application_for(slug)
    posting = JobPosting.find_or_create_by!(signature: slug) do |jp|
      jp.attributes = { title: "Engineer (#{slug})", company: slug.titleize,
                        target_url: "https://boards.greenhouse.io/#{slug}/jobs/1" }
    end
    user.user_job_postings.find_or_create_by!(job_posting: posting)
  end

  def record_all(application)
    PROMPTS.each_with_index { |prompt, index| QuestionOccurrences::Record.call(observation(application, prompt, index)) }
  end

  def observation(application, prompt, index)
    classified = ApplicationFieldQuestionClassifier.call(prompt)
    application.application_field_observations.find_or_create_by!(field_key: "qg_#{index}") do |obs|
      obs.attributes = { field_label: prompt, field_type: "textarea", observed_at: Time.current,
                         question_kind: classified[:question_kind], normalized_prompt: classified[:normalized_prompt] }
    end
  end

  def report(applications)
    @expected = applications.map(&:id).sort
    @archetypes = walkthrough_archetypes.to_a
    { archetypes: @archetypes.size, occurrences: occurrence_counts, provenance_intact: provenance_intact? }
  end

  def occurrence_counts
    @archetypes.map { |archetype| archetype.question_occurrences.count }
  end

  def provenance_intact?
    @archetypes.all? { |archetype| distinct_applications(archetype) == @expected }
  end

  def walkthrough_archetypes
    QuestionArchetype.where(canonical_prompt: PROMPTS.map { |p| ApplicationFieldQuestionClassifier.normalize(p) })
  end

  def distinct_applications(archetype)
    archetype.question_occurrences.pluck(:user_job_posting_id).uniq.sort
  end
end
