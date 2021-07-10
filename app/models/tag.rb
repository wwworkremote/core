class Tag < ApplicationRecord
  has_many :tag_aliases, dependent: :nullify
end

# == Schema Information
# Schema version: 20210710142759
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string           indexed
#  slug       :string           indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
