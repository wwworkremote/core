# frozen_string_literal: true

class ApiController < ActionController::API
  before_action :authenticate_api_token

  private

  def authenticate_api_token
    return if Rails.env.local?

    token = bearer_token
    return if token && ActiveSupport::SecurityUtils.secure_compare(token, api_token)

    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def bearer_token
    request.headers["Authorization"]&.remove("Bearer ")
  end

  def api_token
    ENV.fetch("API_TOKEN") { raise "API_TOKEN must be set in production" }
  end
end
