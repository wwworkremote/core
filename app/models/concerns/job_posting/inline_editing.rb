# frozen_string_literal: true

# TASK-148: virtual accessors the inline edit form on the job posting show
# page binds to. Real storage is the `data` jsonb and the `tags` array column;
# these translate a flat form to it (with dirty tracking), so the controller
# just permits scalars and calls `update`.
module JobPosting::InlineEditing
  extend ActiveSupport::Concern

  SEPARATORS = %r{[,;\n/·]}

  included do
    store_accessor :data, :employment_type, :salary_min, :salary_max, :currency
  end

  def remote
    data["remote"]
  end

  def remote=(value)
    self.data = data.merge("remote" => ActiveModel::Type::Boolean.new.cast(value))
  end

  # `country_code` stays the single geocoded scalar; this is the editable
  # multi-value layer the US-only filter also honors (JobPosting::GeoFiltering).
  def countries
    Array(data["countries"])
  end

  def countries_text
    countries.join(", ")
  end

  def countries_text=(text)
    self.data = data.merge("countries" => split_list(text).map(&:upcase))
  end

  def tags_text
    Array(tags).join(", ")
  end

  def tags_text=(text)
    self.tags = split_list(text)
  end

  private

  def split_list(text)
    text.to_s.split(SEPARATORS).map(&:strip).compact_blank.uniq
  end
end
