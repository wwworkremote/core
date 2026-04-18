# frozen_string_literal: true

# == Schema Information
#
# Table name: origins
# Database name: primary
#
#  id         :bigint           not null, primary key
#  data       :jsonb            not null
#  name       :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Origin < ApplicationRecord
  has_many :sources, dependent: :restrict_with_error
end
