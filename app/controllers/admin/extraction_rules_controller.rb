# frozen_string_literal: true

class Admin::ExtractionRulesController < Admin::ApplicationController
  def index
    @extraction_rules = ExtractionRule.order(provider: :asc, field_name: :asc).page(params[:page]).per(30)
  end

  def show
    @extraction_rule = ExtractionRule.find(params.expect(:id))
    @observations = ExtractionRuleObservation
                    .where(provider: @extraction_rule.provider, field_name: @extraction_rule.field_name)
                    .order(created_at: :desc)
  end
end
