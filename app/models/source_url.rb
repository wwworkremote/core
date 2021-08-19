# frozen_string_literal: true

class SourceUrl < ApplicationRecord
  belongs_to :source
end

# == Schema Information
# Schema version: 20210817230954
#
# Table name: source_urls
#
#  id          :bigint           not null, primary key
#  host        :string
#  path        :string
#  protocol    :string
#  querystring :jsonb            not null
#  url         :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
