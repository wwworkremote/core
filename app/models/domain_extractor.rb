# frozen_string_literal: true

require 'sorted_set'

class DomainExtractor
  attr_reader :name

  def initialize(name)
    @name = name
    @domains = [] unless name.is_a?(String) || name.blank?
  end

  def call
    domains
    self
  end

  def domains
    @domains ||= begin
      data = SortedSet.new

      url = self.class.format(name)

      data << fqdn = begin
        self.class.using_addressable(url)
      rescue StandardError => e
        Sentry.capture_exception(e)
        nil
      end

      data << begin
        self.class.using_public_suffix(fqdn)
      rescue StandardError => e
        Sentry.capture_exception(e)
        nil
      end
      data << begin
        self.class.using_domain_name(fqdn)
      rescue StandardError => e
        Sentry.capture_exception(e)
        nil
      end

      data.compact_blank.sort_by(&:length)
    end
  end

  def self.format(url)
    url = url.to_s.strip.downcase
    url = url.split(']').first.strip # handle upstream parsing error
    return "http://#{url}" unless url.match?(/^http/i)

    url
  end

  def root_domain
    domains.first
  end

  def root?
    domains.one?
  end

  delegate :empty?, to: :domains

  def blank?
    domains.empty?
  end

  def as_json
    {
      name: name,
      domains: domains
    }
  end

  def self.using_addressable(uri)
    Addressable::URI.parse(uri).host
  end

  def self.using_public_suffix(uri)
    PublicSuffix.parse(uri).domain
  end

  def self.using_domain_name(uri)
    DomainName(uri).domain
  end
end
