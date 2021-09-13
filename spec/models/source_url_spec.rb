# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SourceUrl, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: source_urls
#
#  id          :bigint           not null, primary key
#  url         :string           not null
#  protocol    :string
#  host        :string
#  path        :string
#  querystring :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  source_id   :bigint
#
