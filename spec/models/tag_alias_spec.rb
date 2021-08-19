# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TagAlias, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
# Schema version: 20210817230954
#
# Table name: tag_aliases
#
#  id         :bigint           not null, primary key
#  name       :citext           not null, indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  tag_id     :bigint
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => tags.id)
#
