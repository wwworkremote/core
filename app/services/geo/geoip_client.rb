# frozen_string_literal: true

require "maxmind/geoip2"

# rubocop:disable-next Style/ClassAndModuleChildren
module Geo
  class GeoipClient
    DEFAULT_DB_DIR = "data/maxmind"
    SYSTEM_DB_DIRS = ["/opt/homebrew/var/GeoIP", "/usr/share/GeoIP"].freeze
    DEFAULT_CITY_DB_NAME = "GeoLite2-City.mmdb"

    ENV_ALIASES = {
      "MAXMIND_ACCOUNT_ID" => "GEOIP_ACCOUNT_ID",
      "MAXMIND_LICENSE_KEY" => "GEOIP_LICENSE_KEY",
      "MAXMIND_EDITION_IDS" => "GEOIP_EDITION_IDS",
      "MAXMIND_DB_DIR" => nil,
      "MAXMIND_CITY_DB_PATH" => "GEOIP_DB_PATH"
    }.freeze

    class NullClient
      def city(_ip)
        nil
      end
    end

    def self.build(logger: Rails.logger)
      path = resolved_city_db_path
      return missing_database(logger, path) unless File.exist?(path)

      new(reader: MaxMind::GeoIP2::Reader.new(database: path))
    rescue StandardError => e
      failed_initialization(logger, e)
    end

    def self.missing_database(logger, path)
      logger.warn "[GeoipClient] Database not found at #{path}. Geocoding will be disabled."
      NullClient.new
    end

    def self.failed_initialization(logger, error)
      logger.error "[GeoipClient] Failed to initialize: #{error.message}"
      NullClient.new
    end

    def self.env_value(key)
      # Try primary key, then alias
      val = ENV.fetch(key, nil)
      return val if val.present?

      alias_key = ENV_ALIASES[key]
      return nil unless alias_key

      ENV.fetch(alias_key, nil)
    end

    def self.resolved_city_db_path
      explicit = env_value("MAXMIND_CITY_DB_PATH")
      return explicit if explicit.present?

      db_dir = env_value("MAXMIND_DB_DIR") || default_db_dir
      File.join(db_dir, DEFAULT_CITY_DB_NAME)
    end

    def self.default_db_dir
      project_dir = Rails.root.join(DEFAULT_DB_DIR).to_s
      return project_dir if File.file?(File.join(project_dir, DEFAULT_CITY_DB_NAME))

      SYSTEM_DB_DIRS.find { |dir| File.file?(File.join(dir, DEFAULT_CITY_DB_NAME)) } || project_dir
    end

    def initialize(reader:)
      @reader = reader
    end

    def city(ip)
      extract_city_data(@reader.city(ip))
    rescue MaxMind::GeoIP2::AddressNotFoundError
      nil
    rescue StandardError => e
      log_lookup_error(ip, e)
    end

    private

    def log_lookup_error(ip, error)
      Rails.logger.error "[GeoipClient] Lookup error for #{ip}: #{error.message}"
      nil
    end

    def extract_city_data(result)
      identity_fields(result).merge(location_fields(result))
    end

    def identity_fields(result)
      { city: dig(result, :city, :name), region: region_name(result) }
        .merge(country: dig(result, :country, :iso_code), postal_code: dig(result, :postal, :code))
    end

    def location_fields(result)
      {
        latitude: dig(result, :location, :latitude),
        longitude: dig(result, :location, :longitude),
        time_zone: dig(result, :location, :time_zone)
      }
    end

    def dig(obj, *methods)
      methods.reduce(obj) do |memo, method|
        next nil unless memo.respond_to?(method)

        memo.send(method)
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
