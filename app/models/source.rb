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

  has_many :messages, dependent: :nullify
  has_many :job_postings, dependent: :nullify
end

# == Schema Information
# Schema version: 20210707203641
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null, indexed
#  status     :integer          default("pending")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
