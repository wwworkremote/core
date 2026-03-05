# frozen_string_literal: true

class Avo::Filters::SourceFilter < Avo::Filters::SelectFilter
  self.name = 'Filter by Source'

  def apply(_request, query, value)
    query.where(source_id: value)
  end

  def options
    ::Source.all.each_with_object({}) do |source, options|
      options[source.id] = "#{source.origin&.name} (#{source.signature})"
    end
  end
end
