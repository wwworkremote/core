# frozen_string_literal: true

class SourcesSourceUrl < ApplicationRecord
  belongs_to :source
  belongs_to :source_url
end

# == Schema Information
#
# Table name: sources_source_urls
#
#  id            :bigint           not null, primary key
#  source_id     :bigint           not null
#  source_url_id :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
