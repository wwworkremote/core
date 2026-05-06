# frozen_string_literal: true

module Ingestion
  class AdapterRegistry
    @adapters = {}

    def self.register(slug, adapter_class, config = {})
      @adapters[slug.to_s] = {
        class: adapter_class,
        name: config[:name] || slug.to_s.humanize,
        cooldown: config[:cooldown] || 4.hours,
        type: config[:type] || "Standard"
      }
    end

    def self.all
      @adapters
    end

    def self.get(slug)
      @adapters[slug.to_s]
    end
  end
end
