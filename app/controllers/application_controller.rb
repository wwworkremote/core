# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_admin

  def current_user
    @current_user ||= User.find_or_create_by!(email: ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com')) do |u|
      u.name = ENV.fetch('ADMIN_NAME', 'mike')
      u.password = ENV.fetch('ADMIN_PASSWORD', 'password')
    end
  end
  helper_method :current_user

  def authenticate_admin
    # Skip authentication in test environment for simplicity in request specs
    return if Rails.env.test?

    authenticate_or_request_with_http_basic('WWWorkRemote') do |username, password|
      username == ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com') &&
        password == ENV.fetch('ADMIN_PASSWORD', 'password')
    end
  end

  private

end
