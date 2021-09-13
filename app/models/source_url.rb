# frozen_string_literal: true

class SourceUrl < ApplicationRecord
  belongs_to :source, optional: true

  validates :url, presence: true

  before_validation :assign_from_url, on: :create

  def assign_from_url
    params = self.class.params_from(uri: url)

    self.host = params[:host]
    self.protocol = params[:protocol]
    self.path = params[:path]
    self.querystring = params[:querystring]
  end

  def self.params_from(uri:)
    {
      url: uri.to_s,
      host: uri.host,
      protocol: uri.scheme,
      querystring: extract_querystring(uri),
      path: uri.path
    }
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
#
# Table name: source_urls
#
#  id          :bigint           not null, primary key
#  url         :string           not null
#  protocol    :string
#  host        :string
#  path        :string
#  querystring :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  source_id   :bigint
#
