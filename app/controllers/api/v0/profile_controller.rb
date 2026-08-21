# frozen_string_literal: true

# Flattened copy-paste-ready contact fields for the extension's application
# assist (TASK-78) -- single-user system, so no scoping beyond User.first.
class Api::V0::ProfileController < ApiController
  def show
    render json: ProfileContactFields.call(User.first)
  end
end
