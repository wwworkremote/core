# frozen_string_literal: true

Geocoder.configure(
  # geocoding service (look at https://github.com/alexreisnero/geocoder/blob/master/README.md for more)
  lookup: :nominatim,

  # IP address geocoding service
  # ip_lookup: :ipinfo_io,

  # to use an API key:
  # api_key: "...",

  # geocoding service request timeout, in seconds (default 3):
  timeout: 10,

  # set default units to kilometers:
  units: :km,

  # caching (see https://github.com/alexreisnero/geocoder/blob/master/README.md#caching for details)
  # cache: Redis.new,
  # cache_options: {
  #   expiration: 2.days,
  #   prefix: "geocoder:"
  # }

  # Nominatim requires a user agent
  http_headers: { 'User-Agent' => 'wwworkremote-job-aggregator (local-personal-use)' }
)
