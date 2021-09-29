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
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
# Indexes
#
#  index_sources_on_origin_id  (origin_id)
#  index_sources_on_signature  (signature) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (origin_id => origins.id)
#
