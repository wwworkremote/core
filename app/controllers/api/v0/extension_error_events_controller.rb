# frozen_string_literal: true

class Api::V0::ExtensionErrorEventsController < ApiController
  def create
    event = ExtensionErrorEvent.create(event_params.merge(occurred_at: Time.current))
    event.persisted? ? render(json: { success: true, id: event.id }) : render(json: { success: false, errors: event.errors.full_messages }, status: :unprocessable_content)
  end

  private

  def event_params
    params.expect(extension_error_event: %i[build_version event_name phase provider page_host error_name error_message recoverable context])
  end
end
