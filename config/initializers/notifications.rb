# frozen_string_literal: true

# require Rails.root.join('lib/notifications/request_faraday_subscriber.rb')

ActiveSupport::Notifications.monotonic_subscribe('request.faraday') do |event|
  Rails.logger.debug { event.inspect }

  event_json = event.as_json
  payload = event_json.delete('payload')
  signature = Digest::SHA2.hexdigest(payload.deep_sort.to_json)

  # begin
  #   SourceUrl.create_by_uri(event.payload.url)
  # rescue ActiveRecord::RecordNotUnique => e
  #   Rails.logger.error { [e.class, e, e.backtrace.take(10)].inspect }
  # ensure
  begin
    Source.create(
      signature: signature,
      payload: payload,
      event: event_json
    )
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error { [self.class, __method__, e.class, e.message, e.backtrace.take(10)].inspect }
  end
  # end
end
