# frozen_string_literal: true

# Builds the update! attrs hash for Api::JobPostingsController#enrich from the
# extension's extracted field payload: simple column mappings, derived
# fields (parsed date, split skills), and a non-destructive merge into the
# job posting's existing jsonb data column.
class JobPostingEnrichment::AttributeBuilder
  SIMPLE_FIELD_MAP = {
    "title" => :title,
    "company" => :company,
    "location" => :location,
    "apply_url" => :target_url
  }.freeze

  JSONB_KEYS = %w[
    salary_min salary_max salary_currency salary_unit salary
    employment_type remote experience valid_through
    education qualifications responsibilities benefits
    company_logo_url industry
  ].freeze

  def self.call(...)
    new(...).call
  end

  def initialize(job_posting, extracted, markdown_body)
    @job_posting = job_posting
    @extracted = extracted
    @markdown_body = markdown_body
  end

  def call
    column_attrs.merge(data_attrs)
  end

  private

  def column_attrs
    { body: @markdown_body, crawl_status: "enriched", enriched_at: Time.current }.merge(mapped_field_attrs)
  end

  def mapped_field_attrs
    simple_field_attrs.merge(derived_field_attrs)
  end

  def simple_field_attrs
    SIMPLE_FIELD_MAP.each_with_object({}) do |(source_key, attr_key), attrs|
      attrs[attr_key] = @extracted[source_key] if @extracted[source_key].present?
    end
  end

  def derived_field_attrs
    attrs = {}
    attrs[:published_at] = parse_date(@extracted["posted_at"]) if @extracted["posted_at"].present?
    attrs[:tags] = extracted_tags if @extracted["skills"].present?
    attrs
  end

  def extracted_tags
    raw = @extracted["skills"]
    raw.is_a?(Array) ? raw : raw.split(/\s*,\s*/).map(&:strip).compact_blank
  end

  def data_attrs
    patch = JSONB_KEYS.index_with { |key| @extracted[key] }.compact_blank
    patch.any? ? { data: @job_posting.data.merge(patch) } : {}
  end

  def parse_date(val)
    return nil if val.blank?

    Time.zone.parse(val.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
