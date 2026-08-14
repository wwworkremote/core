# frozen_string_literal: true

class Api::ExtractionRulesController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /api/extraction_rules?provider=linkedin
  # Fetched by content.js once per extraction run to apply any learned
  # field-level overrides for the current provider.
  def index
    rules = ExtractionRule.where(provider: params[:provider]).select(:field_name, :selector)
    render json: rules
  end

  # POST /api/extraction_rules
  # Fired when the user teaches a field via the side panel's element picker.
  def create
    selector = JobBoards::SelectorLearnerAgent.new.call(**learner_args)
    rule = upsert_rule(selector)
    log_observation(selector)
    render json: { success: true, selector: rule.selector }
  end

  private

  def log_observation(learned_selector)
    args = params.permit(:provider, :field_name, :candidate_selector, :element_html, :parent_html, :source_url)
    ExtractionRuleObservation.create!(args.merge(learned_selector: learned_selector))
  end

  def learner_args
    { field_name: params[:field_name], candidate_selector: params[:candidate_selector],
      element_html: params[:element_html], parent_html: params[:parent_html] }
  end

  def find_rule
    ExtractionRule.find_or_initialize_by(provider: params[:provider], field_name: params[:field_name])
  end

  def upsert_rule(selector)
    rule = find_rule
    rule.update!(selector: selector, sample_html: params[:element_html], source_url: params[:source_url])
    rule
  end
end
