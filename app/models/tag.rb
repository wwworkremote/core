# frozen_string_literal: true

class Tag < ApplicationRecord
  # has_many :tag_aliases, dependent: :nullify

  # rails_admin do
  #   list do
  #     field :name
  #     field :slug

  #     field :created_at, :datetime do
  #       label 'Created At'
  #       date_format :long
  #     end
  #   end
  # end
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
