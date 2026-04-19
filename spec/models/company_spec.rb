# == Schema Information
#
# Table name: companies
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  status     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_companies_on_slug  (slug)
#
require 'rails_helper'

RSpec.describe Company, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
