# frozen_string_literal: true

require 'maxmind/geoip2'

module Geo
  class GeoipClient
    DEFAULT_DB_DIR = 'data/maxmind'
    DEFAULT_CITY_DB_NAME = 'GeoLite2-City.mmdb'

    ENV_ALIASES = {
      'MAXMIND_ACCOUNT_ID' => 'GEOIP_ACCOUNT_ID',
      'MAXMIND_LICENSE_KEY' => 'GEOIP_LICENSE_KEY',
      'MAXMIND_EDITION_IDS' => 'GEOIP_EDITION_IDS',
      'MAXMIND_DB_DIR' => nil,
      'MAXMIND_CITY_DB_PATH' => 'GEOIP_DB_PATH'
    }.freeze

    class NullClient
      def city(_ip)
        {}
      end
    end

    def self.build(logger: Rails.logger)
      city_db_path = resolved_city_db_path
      unless File.exist?(city_db_path)
        logger.warn("[GeoipClient] Database not found at #{city_db_path}")
        return NullClient.new
      end

      reader = MaxMind::GeoIP2::Reader.new(database: city_db_path)
      new(reader: reader)
    rescue StandardError => e
      logger.warn("[GeoipClient] geoip_init_error=#{e.class} message=#{e.message.inspect} path=#{city_db_path.inspect}")
      NullClient.new
    end

    def self.env_value(key)
      value = ENV.fetch(key, nil)
      return value if value.present?

      alias_key = ENV_ALIASES.fetch(key)
      return nil unless alias_key

      aliased = ENV.fetch(alias_key, nil)
      aliased.presence
    end

    def self.resolved_city_db_path
      explicit = env_value('MAXMIND_CITY_DB_PATH')
      return explicit if explicit

      db_dir = env_value('MAXMIND_DB_DIR') || Rails.root.join(DEFAULT_DB_DIR).to_s
      File.join(db_dir, DEFAULT_CITY_DB_NAME)
    end

    def initialize(reader:)
      @reader = reader
    end

    def city(ip)
      result = @reader.city(ip)
      {
        area_code: nil,
        city_name: dig(result, :city, :name),
        continent_code: dig(result, :continent, :code),
        country_code2: dig(result, :country, :iso_code),
        country_code3: nil,
        country_name: dig(result, :country, :name),
        dma_code: dig(result, :traits, :metro_code),
        ip: ip,
        latitude: dig(result, :location, :latitude),
        longitude: dig(result, :location, :longitude),
        postal_code: dig(result, :postal, :code),
        region_name: region_name(result),
        request: nil,
        timezone: dig(result, :location, :time_zone)
      }
    rescue MaxMind::GeoIP2::AddressNotFoundError
      { ip: ip }
    rescue StandardError => e
      Rails.logger.warn("[GeoipClient] lookup_error=#{e.class} ip=#{ip} message=#{e.message}")
      { ip: ip }
    end

    private

    def dig(obj, *methods)
      methods.reduce(obj) do |memo, method_name|
        break nil unless memo.respond_to?(method_name)

        memo.public_send(method_name)
      end
    end

    def region_name(result)
      subdivisions = result.respond_to?(:subdivisions) ? result.subdivisions : nil
      return nil unless subdivisions&.any?

      region = subdivisions.first
      region.respond_to?(:iso_code) ? region.iso_code : nil
    end
  end
end
