# frozen_string_literal: true

# Wraps ApiClient#search with an OTel span -- one shared cross-cutting
# concern, prepended into each of the four Playwright-based scrapers
# (Dice, Indeed, Glassdoor, LinkedIn) rather than each hand-copying its
# own in_span block. `prepend` (not `include`) so this module's #search
# runs first and can wrap the real implementation via `super`; the four
# classes need no code change beyond `prepend Scraper::Traceable`.
module Scraper::Traceable
  def search(keywords, location)
    tracer.in_span("scraper.search", attributes: span_attributes(keywords, location)) do |span|
      record_result(span, super)
    end
  end

  private

  def tracer
    OpenTelemetry.tracer_provider.tracer("scraper")
  end

  def span_attributes(keywords, location)
    {
      "app.scraper.board" => board_name,
      "app.scraper.keywords" => keywords.to_s,
      "app.scraper.location" => location.to_s
    }
  end

  def board_name
    self.class.name.deconstantize.demodulize.underscore
  end

  def record_result(span, result)
    span.set_attribute("app.scraper.success", result[:success] ? true : false)
    span.set_attribute("app.scraper.count", result[:count]) if result[:count]
    record_error(span, result[:error])
    result
  end

  def record_error(span, error)
    span.status = OpenTelemetry::Trace::Status.error(error.to_s) if error
  end
end
