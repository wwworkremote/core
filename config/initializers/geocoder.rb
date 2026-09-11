# frozen_string_literal: true

require_relative "../../app/services/geo/geoip_client"

Geocoder.configure(
  # geocoding service (look at https://github.com/alexreisnero/geocoder/blob/master/README.md for more)
  lookup: :nominatim,

  # IP address geocoding service
  ip_lookup: :geoip2,

  # configuration options for geoip2
  geoip2: {
    file: Geo::GeoipClient.resolved_city_db_path
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
    prefix: "geocoder:"
  },

  # Nominatim requires a user agent
  http_headers: { "User-Agent" => "WWWorkRemote (mike@just3ws.com)" }
)
