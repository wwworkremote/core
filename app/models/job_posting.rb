# frozen_string_literal: true

class JobPosting < ApplicationRecord
  enum status: {
    pending: 0,
    processed: 1
  }, _prefix: true

  belongs_to :source, optional: true

  before_validation :sign, on: :create
  after_commit :update_source, on: :create

  validates :signature, presence: true

  def update_source
    source.status_processed! unless source.status_processed?
  end

  private

  def sign # rubocop:disable Metrics/MethodLength
    self.signature ||= Digest::SHA2.hexdigest(
      [
        title,
        body,
        company,
        external_author_id,
        location,
        published_at,
        tags&.sort&.join,
        target_url
      ].join
    )
  end
end

# == Schema Information
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  signature          :string           not null
#  status             :integer          default("pending")
#  source_id          :bigint
#  title              :string
#  body               :string
#  company            :string
#  location           :string
#  external_author_id :string
#  external_id        :string
#  published_at       :datetime
#  tags               :string           is an Array
#  target_url         :string
#  data               :jsonb            not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
