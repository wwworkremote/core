# frozen_string_literal: true

class Source < ApplicationRecord
  has_many :job_postings, dependent: :nullify

  def payload_url
    payload&.send(:[], 'url')
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
