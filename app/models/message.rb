# frozen_string_literal: true

class Message < ApplicationRecord
  enum status: {
    pending: 0,
    processed: 1
  }, _prefix: true

  belongs_to :source, optional: true

  after_commit :update_source, on: :create

  def update_source
    source.status_processed! unless source.status_processed?
  end

  jsonb_accessor :data,
                 body: :string,
                 company: :string,
                 external_author_id: :string,
                 external_id: :string,
                 location: :string,
                 published_at: :datetime,
                 tags: [:string, { array: true, default: [] }],
                 target_url: :string,
                 title: :string
end

# == Schema Information
# Schema version: 20210707203641
#
# Table name: messages
#
#  id         :bigint           not null, primary key
#  data       :jsonb            not null
#  status     :integer          default("pending")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  source_id  :bigint           indexed
#
