# frozen_string_literal: true

class SourceUrl < ApplicationRecord
  belongs_to :source, optional: true

  def self.create_by_uri(uri)
    create(
      url: uri.to_s,
      host: uri.host,
      protocol: uri.scheme,
      querystring: extract_querystring(uri),
      path: uri.path
    )
  end

  def self.extract_querystring(uri)
    return unless uri&.query

    uri
      .query
      .split('&')
      .map { |kv| kv.split('=') }
      .each_with_object({}) { |kv, h| h[kv.first] = kv.last }
      .deep_sort
  end
end

# == Schema Information
# Schema version: 20210817230954
#
# Table name: source_urls
#
#  id          :bigint           not null, primary key
#  host        :string
#  path        :string
#  protocol    :string
#  querystring :jsonb            not null
#  url         :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
