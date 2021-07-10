# frozen_string_literal: true

class Message < ApplicationRecord
  enum status: {
    pending: 0,
    processed: 1
  }, _prefix: true

  belongs_to :source, optional: true
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
