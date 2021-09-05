# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tag, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end

# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  slug       :string
#  name       :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
