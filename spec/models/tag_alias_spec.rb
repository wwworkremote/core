# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagAlias, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: tag_aliases
#
#  id         :bigint           not null, primary key
#  tag_id     :bigint
#  name       :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
