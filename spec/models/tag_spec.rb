require 'rails_helper'

RSpec.describe Tag, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
# Schema version: 20210712004243
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :citext           indexed
#  slug       :string           indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
