# frozen_string_literal: true

class Origin < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged
end

# == Schema Information
#
# Table name: origins
#
#  id         :bigint           not null, primary key
#  slug       :string
#  name       :citext
#  data       :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
