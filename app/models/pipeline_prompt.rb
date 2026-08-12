# frozen_string_literal: true

# Admin-editable AI prompts used at specific points in the ingestion/matching
# pipeline (categorization, match scoring, company auditing, ...). Each
# integration point looks itself up by a stable `key` via .render_for and
# falls back to its original hardcoded prompt if no active row exists --
# creating a PipelinePrompt is opt-in, not a requirement to keep the
# pipeline running.
# == Schema Information
#
# Table name: pipeline_prompts
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  body        :text             not null
#  description :text
#  key         :string           not null
#  name        :string           not null
#  stage       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_pipeline_prompts_on_key  (key) UNIQUE
#
class PipelinePrompt < ApplicationRecord
  # Documents the ERB locals each known integration point passes to
  # .render_for, purely for the admin form's benefit (not enforced) --
  # keep in sync with the locals hash at each call site (see
  # app/agents/job_boards/categorizer_agent.rb,
  # app/agents/job_boards/strategy_agent.rb,
  # app/services/LLM/profile_matcher/prompt_builder.rb,
  # app/services/LLM/company_auditor.rb).
  KNOWN_KEYS = {
    "job_boards_categorizer" => "No locals -- template can reference JobBoards::Categorizer::CATEGORIES directly.",
    "job_boards_strategy" => "No locals -- job posting/fit analysis/company research are inlined into the prompt.",
    "profile_matcher_deep_scan" => "profile, job_posting, experiences_context, github_synthesis, extra_documents",
    "company_auditor" => "company_name, raw_feedback"
  }.freeze

  validates :key, presence: true, uniqueness: true
  validates :name, :stage, :body, presence: true

  scope :active, -> { where(active: true) }

  # Renders the named prompt's ERB body with the given locals bound as
  # local variables. Falls back to the block's return value (the call
  # site's original hardcoded prompt) when no active row exists for `key`
  # or when a syntax error/unbound local blows up ERB rendering -- a
  # broken saved prompt should degrade to the known-good default, not take
  # the pipeline down.
  def self.render_for(key, locals = {}, &)
    prompt = active.find_by(key: key)
    return yield if prompt.nil?

    render_body(prompt.body, locals, &)
  end

  def self.render_body(body, locals)
    ERB.new(body).result_with_hash(locals)
  rescue StandardError => e
    Rails.logger.error "[PipelinePrompt] Failed to render prompt: #{e.message}"
    yield
  end
  private_class_method :render_body
end
