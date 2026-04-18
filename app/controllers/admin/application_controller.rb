# frozen_string_literal: true

module Admin
  class ApplicationController < ::ApplicationController
    # Inherits from ::ApplicationController which already has `before_action :authenticate_admin`
    # and the Basic Auth logic.

    # We can add admin-specific layout or helpers here if needed
    layout 'application'
  end
end
