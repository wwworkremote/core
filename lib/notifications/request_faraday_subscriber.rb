# frozen_string_literal: true

ActiveSupport::Notifications.monotonic_subscribe('request.faraday') do |event|
  event_json = event.as_json
  payload = event_json.delete('payload')
  signature = Digest::SHA2.hexdigest(payload.deepsort.to_json)

  begin
    ::Notifications::RequestFaraday.create(
      signature: signature,
      payload: payload,
      event: event_json
    )
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.debug { [e.class, e].inspect }
  end
end
