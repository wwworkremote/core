# frozen_string_literal: true

class Source < ApplicationRecord
  validates :signature, presence: true, uniqueness: true

  belongs_to :origin, optional: true
  has_many :job_postings, -> { readonly }, dependent: :restrict_with_error, inverse_of: :source

  jsonb_accessor :event, name: :string
  jsonb_accessor :payload, url: :string

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name signature created_at updated_at origin_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[origin job_postings]
  end

  # rails_admin do
  #   list do
  #     field :event

  #     field :name
  #     field :url

  #     sort_by :created_at
  #     sort_by :id

  #     field :created_at, :datetime do
  #       label 'Created At'
  #       date_format :long
  #       sort_reverse true
  #     end

  #     field :id do
  #       label 'ID'
  #       sort_reverse true
  #     end
  #   end
  # end
end

# == Schema Information
#
# Table name: sources
#
#  id         :bigint           not null, primary key
#  event      :jsonb            not null
#  payload    :jsonb            not null
#  signature  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  origin_id  :bigint
#
# Indexes
#
#  index_sources_on_origin_id  (origin_id)
#  index_sources_on_signature  (signature) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (origin_id => origins.id)
#
