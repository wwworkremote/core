# frozen_string_literal: true

class Source < ApplicationRecord
  has_many :job_postings, dependent: :nullify

  belongs_to :origin, optional: true

  before_save :assign_origin_by_url, unless: -> { origin.presence }

  def payload_url
    payload&.send(:[], 'url')
  end

  def assign_origin_by_url
    return if payload&.send(:[], 'url').blank?

    name = URI.parse(payload['url']).host

    self.origin_id = Origin.find_or_create_by(name: name).id

    # Source.find_each { |s| s.assign_origin_by_url.save! }
    self
  end
end

# == Schema Information
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  signature  :string           not null
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
