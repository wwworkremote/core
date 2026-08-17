# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authenticatable

  before_action :authenticate_admin

  def authenticate_admin
    return if skip_admin_auth?

    authenticate_or_request_with_http_basic("WWWorkRemote") do |username, password|
      admin_credentials?(username, password)
    end
  end

  private

  # Only ever a same-app relative path is returned -- never the full referer
  # -- so a later redirect_to built from it can't be steered off this host
  # regardless of what a crafted Referer header contains.
  def safe_return_path(referer)
    return nil if referer.blank?

    uri = URI.parse(referer)
    uri.host == request.host ? uri.request_uri : nil
  rescue URI::InvalidURIError
    nil
  end

  # Validates a value that's already supposed to be a same-app relative path
  # (e.g. round-tripped through a hidden form field) -- rejects anything that
  # isn't root-relative, including a protocol-relative "//evil.com/x" (which
  # browsers resolve as https://evil.com/x, a classic open-redirect vector).
  def safe_local_path(path)
    return nil if path.blank?

    path.start_with?("/") && !path.start_with?("//") ? path : nil
  end

  def skip_admin_auth?
    # Skip authentication in test environment for simplicity in request specs
    return true if Rails.env.test?

    # This only ever runs on loopback (dev server + nginx .localhost vhost) --
    # no point challenging for a password to log in as the one admin account
    # current_user already resolves to unconditionally.
    Rails.env.development?
  end

  def admin_credentials?(username, password)
    username == ENV.fetch("ADMIN_EMAIL", "mike@just3ws.com") &&
      password == ENV.fetch("ADMIN_PASSWORD", "password")
  end

  def available_chat_models
    Model.any? ? database_chat_models : registry_chat_models
  end

  # Prioritize "ollama" provider at the top
  def database_chat_models
    Model.order(Arel.sql("CASE WHEN provider = 'ollama' THEN 0 ELSE 1 END"), :name)
  end

  def registry_chat_models
    RubyLLM.models.chat_models.all.sort_by { |model| [model.provider == :ollama ? 0 : 1, model.name.to_s] }
  end
end
