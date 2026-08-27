# frozen_string_literal: true

class Api::GuidedSessionEventsController < ApplicationController
  skip_before_action :authenticate_admin
  skip_before_action :verify_authenticity_token

  def create
    return head :not_found unless Rails.env.local?

    record_event
  end

  private

  def record_event
    event = guided_session.guided_session_events.new(event_params)
    return render_validation_error(event) unless event.save

    render json: event_response(event), status: :created
  end

  def guided_session
    @guided_session ||= GuidedSession.find_by!(session_token: params.expect(:session_token))
  end

  def event_params
    fields = %i[kind action intent requirement reversibility approval_state page_url]
    params.expect(event: fields + [{ evidence: {} }])
  end

  def render_validation_error(event)
    render json: { errors: event.errors.full_messages }, status: :unprocessable_content
  end

  def event_response(event)
    response = event.attributes.slice("id", "phase", "kind", "intent", "requirement", "reversibility", "approval_state")
    response["success"] = true
    response
  end
end
