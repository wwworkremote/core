# frozen_string_literal: true

Geocoder.configure(
  # geocoding service (look at https://github.com/alexreisnero/geocoder/blob/master/README.md for more)
  lookup: :nominatim,

  # IP address geocoding service
  ip_lookup: :geoip2,

  # configuration options for geoip2
  geoip2: {
    file: Rails.root.join('data/maxmind/GeoLite2-City.mmdb')
  },

  # to use an API key:
  # api_key: "...",

  # geocoding service request timeout, in seconds (default 3):
  timeout: 10,

  # always raise errors (see https://github.com/alexreisnero/geocoder/blob/master/README.md#error-handling)
  always_raise: :all,

  # set default units to kilometers:
  units: :km,

  # caching (see https://github.com/alexreisnero/geocoder/blob/master/README.md#caching for details)
  cache: Rails.cache,
  cache_options: {
    expiration: 1.month,
    prefix: 'geocoder:'
  },

  # Nominatim requires a user agent
  http_headers: { 'User-Agent' => 'WWWorkRemote (mike@just3ws.com)' }
)
