# frozen_string_literal: true

# require Rails.root.join('lib/notifications/request_faraday_subscriber.rb')

ActiveSupport::Notifications.monotonic_subscribe('request.faraday') do |event|
  event_json = event.as_json
  payload = event_json.delete('payload')
  signature = Digest::SHA2.hexdigest(payload.deep_sort.to_json)

  context = Rails.configuration.x.context.merge(signature: signature)

  begin
    Source.create(
      signature: signature,
      payload: payload,
      event: event_json
    )
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation => e
    Sentry.capture_exception(e)
    Rails.logger.debug { ['Duplicate signature', context] }
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error(e.message, context.merge(signature: signature))
    Rails.logger.debug { e }
  end
end
