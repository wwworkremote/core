# frozen_string_literal: true

class JobPosting < ApplicationRecord
  belongs_to :source, optional: true

  before_validation :sign, on: :create

  validates :signature, presence: true

  private

  def sign
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
#  body               :string
#  company            :string
#  data               :jsonb            not null
#  location           :string
#  published_at       :datetime
#  signature          :string           not null
#  tags               :string           is an Array
#  target_url         :string
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  external_author_id :string
#  external_id        :string
#  source_id          :bigint
#
# Indexes
#
#  index_job_postings_on_source_id  (source_id)
#
