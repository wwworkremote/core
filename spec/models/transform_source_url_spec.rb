# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransformSourceUrl, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
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
