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

  after_commit :infer_origin, on: :create

  def infer_origin
    host = URI.parse(Source.last.payload['url']).host

    self.origin = Origin.find_or_create_by(name: host)
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
