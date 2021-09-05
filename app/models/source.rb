# frozen_string_literal: true

class Source < ApplicationRecord
  enum status: {
    empty: -1,
    pending: 0,
    processed: 1
  }, _prefix: true

  scope :empty, -> { where(status: -1) }
  scope :pending, -> { where(status: 0) }
  scope :processed, -> { where(status: 1) }

  has_many :job_postings, dependent: :nullify

  belongs_to :origin, optional: true

  before_save :assign_origin_by_url, unless: -> { origin.presence }

  def assign_origin_by_url
    return if payload&.send(:[], 'url').blank?

    name = URI.parse(payload['url']).host

    self.origin = Origin.find_or_create_by(name: name)

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
#  status     :integer          default("pending")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
