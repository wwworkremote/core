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

  def sign
    self.signature ||= Digest::SHA2.hexdigest([title, body, company, external_author_id, location, published_at, tags&.sort&.join, target_url].join)
  end
end

# == Schema Information
# Schema version: 20210817230954
#
# Table name: job_postings
#
#  id                 :bigint           not null, primary key
#  body               :string
#  company            :string
#  data               :jsonb            not null
#  location           :string
#  published_at       :datetime
#  signature          :string           not null
#  status             :integer          default("pending")
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint           indexed
#
