# frozen_string_literal: true

class Ingestion::AdapterRegistry
  # Populated once at boot via config/initializers/ingestion_adapters.rb's
  # to_prepare block (reset fresh on each Zeitwerk reload in development) --
  # not a runtime concurrency hazard, so freezing it (which would break
  # #register) isn't the right fix for ThreadSafety's warnings below.
  # rubocop:disable ThreadSafety/MutableClassInstanceVariable, ThreadSafety/ClassInstanceVariable
  @adapters = {}

  def self.register(slug, adapter_class, config = {})
    @adapters[slug.to_s] = adapter_entry(slug, adapter_class, config)
  end

  # One cohesive hash literal -- splitting it further would obscure it,
  # not simplify it.
  # rubocop:disable-next Metrics/MethodLength
  def self.adapter_entry(slug, adapter_class, config)
    {
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
  # rubocop:enable ThreadSafety/MutableClassInstanceVariable, ThreadSafety/ClassInstanceVariable
end
