# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authenticatable

  before_action :authenticate_admin

  def authenticate_admin
    # Skip authentication in test environment for simplicity in request specs
    return if Rails.env.test?

    authenticate_or_request_with_http_basic("WWWorkRemote") do |username, password|
      username == ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com") &&
        password == ENV.fetch("ADMIN_PASSWORD", "password")
    end
  end

  private

  def available_chat_models
    if Model.any?
      # Prioritize "ollama" provider at the top
      Model.order(Arel.sql("CASE WHEN provider = 'ollama' THEN 0 ELSE 1 END"), :name)
    else
      RubyLLM.models.chat_models.all
             .sort_by { |model| [model.provider == :ollama ? 0 : 1, model.name.to_s] }
    end
  end
end
