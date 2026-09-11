# frozen_string_literal: true

# Trigram similarity search over Company#name, used by the extension's
# capture-review panel to offer existing-company matches before the user
# decides whether to link one or create a new Company record.
class Companies::FuzzyMatcher
  def self.call(...)
    new(...).call
  end

  def initialize(query, limit: 8)
    @query = query
    @limit = limit
  end

  def call
    return Company.none if @query.blank?

    Company.where("name % ?", @query)
           .order(Arel.sql("similarity(name, #{sanitized_query}) DESC"))
           .limit(@limit)
  end

  private

  def sanitized_query
    Company.sanitize_sql_array(["?", @query])
  end
end
