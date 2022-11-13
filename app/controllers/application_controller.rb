# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def current_user
    @current_user ||= User
                      .create_with(name: 'Mike Hall', email: 'mike@just3ws.com')
                      .find_or_create_by(slug: 'mike.hall')
  end
end
