# frozen_string_literal: true

class TransformSourceUrl < ApplicationRecord
end

# == Schema Information
# Schema version: 20210817230954
#
# Table name: transform_source_urls
#
#  host        :text
#  path        :text
#  protocol    :text
#  querystring :jsonb
#  url         :text
#  source_id   :bigint
#
