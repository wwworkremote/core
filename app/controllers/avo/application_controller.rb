module Avo
  class ApplicationController < Avo::BaseApplicationController
    def current_user
      @current_user ||= User.find_or_create_by!(email: ENV.fetch('ADMIN_EMAIL', 'mike@just3ws.com')) do |u|
        u.name = ENV.fetch('ADMIN_NAME', 'mike')
        u.password = ENV.fetch('ADMIN_PASSWORD', 'password')
      end
    end
    helper_method :current_user
  end
end
