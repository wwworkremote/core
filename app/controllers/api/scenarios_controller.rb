# frozen_string_literal: true

class Api::ScenariosController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Deliberate Phase A capture endpoint. The extension uses this only for the
  # local sandbox, while routine lead captures continue through Api::LeadsController.
  def create
    return head :not_found unless Rails.env.local?

    render json: scenario_response(capture_scenario), status: :created
  end

  private

  def capture_scenario
    Scenarios::Capture.call(scenario_source, provider: scenario_provider,
                                             scenario: existing_scenario)
  end

  def scenario_response(scenario)
    {
      success: true,
      scenario_token: scenario.scenario_token,
      signatures: scenario.scenario_signatures.pluck(:kind, :value)
    }
  end

  def scenario_source
    scenario_params.fetch(:source)
  end

  def scenario_provider
    scenario_params[:provider]
  end

  def existing_scenario
    token = scenario_params[:scenario_token]
    Scenario.find_by!(scenario_token: token) if token.present?
  end

  def scenario_params
    params.permit(:provider, :source, :scenario_token)
  end
end
